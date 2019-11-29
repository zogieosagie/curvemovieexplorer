//
//  CurveMovieExplorerViewModel.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 28/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import Foundation

protocol CurveMovieExplorerViewModelProtocol {
    func userViewModelUpdatedUsersList(with newIndexPathsToReload: [IndexPath]?, andErrorMessage errorMessage: String?)
    func userModelUpdatedItem(atRow row:Int)
}


struct NetworkResponse :Codable {
    var fetchedMovies :[Movie]
    let totalResults :Int
    let page :Int
    
    enum CodingKeys: String, CodingKey {
        case fetchedMovies = "results"
        case totalResults = "total_results"
        case page = "page"
    }
}

class CurveMovieExplorerViewModel :NSObject, URLSessionDownloadDelegate {
    
    private let kResourceBaseUrl = "https://api.themoviedb.org/3/movie/popular?"
    private let kResourceUrlQuery = "api_key=331267eab0795c04483f55976e7ef214&language=en-US&page="
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var movies :[Movie]!
    private var totalNumberOfMovies = 0
    private let networkQueryService = NetworkQueryService()
    private var networkDownloadService :NetworkDownloadService?
    private var currentPage = 1
    private var isFetchInProgress = false
    
    private var networkResponse :Codable = [Movie]()
    
    var usersViewModelDelegate :CurveMovieExplorerViewModelProtocol?
    
    override init() {
        super.init()
        networkDownloadService = NetworkDownloadService(withDelegate: self)
        movies = [Movie]()
    }
    
    init(withMovies moviesForInit :[Movie]) {
        super.init()
        movies = moviesForInit
        networkDownloadService = NetworkDownloadService(withDelegate: self)
    }
    
    func fetchMovies()
    {
        guard !isFetchInProgress else {
          return
        }
        isFetchInProgress = true
        
        let pageToFetch = "\(currentPage)"
        networkQueryService.performNetworkQuery(withBaseUrlString: kResourceBaseUrl, andQueryString: (kResourceUrlQuery + pageToFetch), completion: processNetworkQuery(returnedData:queryError:))
    }
    
    func processNetworkQuery(returnedData data :Data?, queryError error :Error?){
        
        isFetchInProgress = false
        
        //Notify delegate with error when we are done.
        if(error == nil){
            do{
                self.currentPage += 1
                self.isFetchInProgress = false
                
                
                let networkResponse = try JSONDecoder().decode(NetworkResponse.self, from: data!)
                self.movies.append(contentsOf: networkResponse.fetchedMovies)
                totalNumberOfMovies = networkResponse.totalResults
                
                if(networkResponse.page > 1){
                let indexPathsToReload = self.computeIndexPathsToReload(from: networkResponse.fetchedMovies)
                self.usersViewModelDelegate?.userViewModelUpdatedUsersList(with :indexPathsToReload, andErrorMessage: nil)
                }
                else{
                    self.usersViewModelDelegate?.userViewModelUpdatedUsersList(with :nil, andErrorMessage: nil)
                }
                
            }
            catch{
                self.usersViewModelDelegate?.userViewModelUpdatedUsersList(with :nil, andErrorMessage: NSLocalizedString("List of movies could not be retrieved.", comment: "NEEDS_LOCALIZATION"))
            }
        }
        else{
            
            self.usersViewModelDelegate?.userViewModelUpdatedUsersList(with :nil, andErrorMessage: error?.localizedDescription)
        }
        
    }
    
    private func computeIndexPathsToReload(from newlyFetchedMovies: [Movie]) -> [IndexPath] {
      let startIndex = movies.count - newlyFetchedMovies.count
      let endIndex = startIndex + newlyFetchedMovies.count
      return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
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
    
    func voteAveragePercentString(forCellAtIndex cellIndex :Int) -> String
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
        
        return totalNumberOfMovies
    }
    
    func currentCount() -> Int{
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
