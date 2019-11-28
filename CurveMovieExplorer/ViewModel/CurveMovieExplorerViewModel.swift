//
//  CurveMovieExplorerViewModel.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 28/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import Foundation

protocol CurveMovieExplorerViewModelProtocol {
    func userViewModelUpdatedUsersList(withErrorMessage errorMessage :String?)
    func userModelUpdatedItem(atRow row:Int)
}


struct NetworkResponse :Codable {
    var fetchedMovies :[Movie]
    
    enum CodingKeys: String, CodingKey {
        case fetchedMovies = "results"
    }
}

class CurveMovieExplorerViewModel :NSObject, URLSessionDownloadDelegate {
    
    let kResourceBaseUrl = "https://api.themoviedb.org/3/movie/popular?"
    let kResourceUrlQuery = "api_key=331267eab0795c04483f55976e7ef214&language=en-US&page=1"
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    var usersViewModelDelegate :CurveMovieExplorerViewModelProtocol?
    var movies = [Movie]()
    let networkQueryService = NetworkQueryService()
    var networkDownloadService :NetworkDownloadService?
    
    var networkResponse :Codable = [Movie]()
    
    override init() {
        super.init()
        networkDownloadService = NetworkDownloadService(withDelegate: self)
    }
    
    func fetchMovies()
    {
        networkQueryService.performNetworkQuery(withBaseUrlString: kResourceBaseUrl, andQueryString: kResourceUrlQuery, completion: processNetworkQuery(returnedData:queryError:))
    }
    
    func processNetworkQuery(returnedData data :Data?, queryError error :Error?){
        
        movies = [Movie]()
        
        //Notify delegate with error when we are done.
        if(error == nil){
            do{
                
                movies = try JSONDecoder().decode(NetworkResponse.self, from: data!).fetchedMovies
                self.usersViewModelDelegate?.userViewModelUpdatedUsersList(withErrorMessage: nil)
                
            }
            catch{
                self.usersViewModelDelegate?.userViewModelUpdatedUsersList(withErrorMessage: NSLocalizedString("List of movies could not be retrieved.", comment: "NEEDS_LOCALIZATION"))
            }
        }
        else{
            
            self.usersViewModelDelegate?.userViewModelUpdatedUsersList(withErrorMessage: error?.localizedDescription)
        }
        
    }
    
    func movieTitle(forCellAtIndex cellIndex :Int) -> String
    {
        var movieTitle = ""
        
        if(cellIndex < movies.count){
            movieTitle = movies[cellIndex].movieTitle
        }
        return movieTitle
    }
    
    func movieOverview(forCellAtIndex cellIndex :Int) -> String
    {
        var movieOverview = ""
        
        if(cellIndex < movies.count){
            movieOverview = movies[cellIndex].movieOverview
        }
        return movieOverview
    }
    
    func releaseDate(forCellAtIndex cellIndex :Int) -> String
    {
        var releaseDate = ""
        
        if(cellIndex < movies.count){
            releaseDate = movies[cellIndex].releaseDate
        }
        return releaseDate
    }
    
    func voteAverage(forCellAtIndex cellIndex :Int) -> String
    {
        var voteAverageString = "N/A"
        var voteAverage :Double?
        
        if(cellIndex < movies.count){
            voteAverage = movies[cellIndex].voteAverage
        }
        
        if(voteAverage != nil){
            let pctVoteAverage = voteAverage! * 10.0
            voteAverageString = "\(pctVoteAverage)%"
            
        }
        
        return voteAverageString
    }
    
    /*
      If this image has been previously downloaded, return the path to the image. However it it hasn't return nil and initiate its download. The delegate will be notified when download is complete.
     
     */
    func imagePath(forCellAtIndex cellIndex :Int) -> URL?
    {
        var localImageUrl :URL?
        
        if(cellIndex < movies.count){
            localImageUrl = movies[cellIndex].localImageUrl
            
            if(localImageUrl == nil){
    
                let imageDownloadPrefix = "https://image.tmdb.org/t/p/w500"
                let imagePath = movies[cellIndex].imagePath
                guard let remoteImageUrl = URL(string: imageDownloadPrefix + imagePath) else { return nil }
                networkDownloadService?.startDownloading(resourceWithURL: remoteImageUrl, atIndex: cellIndex)
                
            }
        }
        return localImageUrl
    }
    
    func favouriteStatus(forCellAtIndex cellIndex :Int) -> Bool
    {
        var favouriteStatus = false
        
        if(cellIndex < movies.count){
            favouriteStatus = movies[cellIndex].isFavourite
        }
        return favouriteStatus
    }
    
    
    func numberOfMovies() -> Int{
        
        return movies.count
    }
    
    func toggleFavouriteRequest(forItem itemIndex:Int)
    {
        let thisMovie = movies[itemIndex]
        thisMovie.isFavourite = !thisMovie.isFavourite
        
        self.usersViewModelDelegate?.userModelUpdatedItem(atRow: itemIndex)
    }
    
    
    
    //MARK: URLSession delegate
    
    /*
     When download is complete:
     1. Find out the index of the item that initiated the download. This will enable us send a specific message to the delegate to reload an item rather than everything.
     2. Copy the image to disk.
     3. Update the local imagepath url for the model
     4. Notify the delegate.
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
          return
        }
        
        let indexOfDownload = networkDownloadService?.downloadsinProgress[sourceURL]
        
        guard indexOfDownload != nil else{
            return
        }
        
        networkDownloadService?.downloadsinProgress[sourceURL] = nil
        let destinationURL = localFilePath(for: sourceURL)
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)

        do {
          try fileManager.copyItem(at: location, to: destinationURL)
        } catch _ {
          return
        }
        
        guard indexOfDownload! < movies.count else {
            return
        }
        
        let thisMovie = movies[indexOfDownload!]
        thisMovie.updateLocalImageUrl(updateUrl: destinationURL)
        
      DispatchQueue.main.async { [weak self] in
        self?.usersViewModelDelegate?.userModelUpdatedItem(atRow: indexOfDownload!)
      }
    }
    
    func localFilePath(for url: URL) -> URL {
      return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
    
    
}
