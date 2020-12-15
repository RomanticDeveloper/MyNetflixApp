//
//  SearchViewController.swift
//  MyNetflix
//
//  Created by joonwon lee on 2020/04/02.
//  Copyright © 2020 com.joonwon. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    
    var movies: [Movie] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}


extension SearchViewController: UICollectionViewDataSource{    // data
    
    // 몇개
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    
    // 어떻게 표현
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCell", for: indexPath) as? ResultCell else {
                return UICollectionViewCell()
            
        }
        let movie = movies[indexPath.item]
        //image Path -> image
        //3rd party lib 사용
        //SPM , Cocoa Pod, Carthage
        let url = URL(string: movie.thumbnailPath)!
        cell.movieThumbnail.kf.setImage(with: url)

        return cell
    }

    
}

extension SearchViewController: UICollectionViewDelegate{ // click
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = movies[indexPath.item]
        let url = URL(string: movie.previewURL)!
        let item = AVPlayerItem(url: url)
        
        let sb = UIStoryboard(name: "Player", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
        vc.modalPresentationStyle = .fullScreen
        
        vc.player.replaceCurrentItem(with: item)
        
        present(vc, animated: false, completion: nil)
    }
}

extension SearchViewController: UICollectionViewDelegateFlowLayout{ // flexible layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let margin: CGFloat = 8
        let itemSpacing: CGFloat = 10
        
        let width = (collectionView.bounds.width - margin * 2 - itemSpacing * 2) / 3
        let height = width * 10/7
        
        return CGSize(width: width, height: height)
    }
}

class ResultCell: UICollectionViewCell {
    @IBOutlet weak var movieThumbnail: UIImageView!
}



extension SearchViewController: UISearchBarDelegate {
    
    private func dismissKeyboard() { // 첫번째 응답자가 아니도록 리자인
        searchBar.resignFirstResponder()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // 검색 시작
        
        //키보드가 올라와 있을때, 내려가게 처리
        dismissKeyboard()
        
        //검색어가 있는지 체크
        guard let searchTerm = searchBar.text,
              searchTerm.isEmpty == false else { return }
        
        
        //네트워킹을 통한 검색
        // - 목표 : 서치텀을 가지고 네트워킹을 통해서 영화. 검색
        // - [x]검색 API 필요
        // - [x]검색 결과를 받아올 Movie 객체 필요, Response 도 같이 필요함
        // - 결과를 받아와서. Collection View 로 표현
        
        SearchAPI.search(searchTerm) { movies in
            //collectionView 로 표현하기
            DispatchQueue.main.async { //UI 수정은 main Thread 에서 동작하도록 변경
                self.movies = movies
                self.resultCollectionView.reloadData()
            }

            
        }
        print("-->검색어 \(searchTerm)")
    }
}

class SearchAPI {
    
    static func search(_ term: String, completion: @escaping ([Movie]) -> Void){
        let session = URLSession(configuration: .default)
        //URLComponents
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
        let mediaQuery = URLQueryItem(name: "media", value: "movie")
        let entityQuery = URLQueryItem(name: "entity", value: "movie")
        let termQuery = URLQueryItem(name: "term", value: term)

        urlComponents.queryItems?.append(mediaQuery)
        urlComponents.queryItems?.append(entityQuery)
        urlComponents.queryItems?.append(termQuery)
        let requestURL = urlComponents.url!
        
        let dataTask = session.dataTask(with: requestURL) { data, response, error in
            let successReange = 200..<300
            
            guard error == nil,
                  let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  successReange.contains(statusCode) else {
                completion([])
                return
        
            }
            
            
            guard let resultData = data else {
                completion([])
                return
            }
            
            let movies = SearchAPI.parseMovies(resultData)
            completion(movies)
            print("--> result : \(movies.count)")
            
                  
            
            
        }
        dataTask.resume()
    }
    
    
    static func parseMovies(_ data: Data) -> [Movie] {
        let decoder = JSONDecoder()
        
        do{
            let response = try decoder.decode(Response.self, from: data)
            let movies = response.movies
            return movies
        }catch let error {
            print ("--> parsing error: \(error.localizedDescription)")
            return []
        }
        
        
    }
}

struct Response: Codable {
    let resultCount: Int
    let movies: [Movie]
    
    enum CodingKeys: String, CodingKey{
        case resultCount
        case movies = "results"
    }
}


struct Movie: Codable{
    let title: String
    let director: String
    let thumbnailPath: String
    let previewURL: String
    
    enum CodingKeys: String, CodingKey{
        case title = "trackName"
        case director = "artistName"
        case thumbnailPath = "artworkUrl100"
        case previewURL = "previewUrl"
    }
}

