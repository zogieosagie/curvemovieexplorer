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

class CurveMovieExplorerViewModel :NSObject, NetworkDownloadServiceProtocol {

    private let kResourceBaseUrl = "https://api.themoviedb.org/3/movie/popular?"
    private let kResourceUrlQuery = "api_key=331267eab0795c04483f55976e7ef214&language=en-US&page="
    
    var movies = [Movie]()
    private var totalNumberOfMovies = 0
    private var networkQueryService  :NetworkQueryService!
    private var networkDownloadService :NetworkDownloadService!
    private var currentPage = 1
    private var isFetchInProgress = false
        
    var usersViewModelDelegate :CurveMovieExplorerViewModelProtocol?
    
    init(withQueryService queryService :NetworkQueryService, andDownloadService downloadService :NetworkDownloadService) {
        super.init()
        self.networkDownloadService = downloadService
        self.networkDownloadService.networkDownloadServiceDelegate = self
        
        self.networkQueryService = queryService
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
                
                
                let movieCollection = try JSONDecoder().decode(MovieCollection.self, from: data!)
                self.movies.append(contentsOf: movieCollection.fetchedMovies)
                totalNumberOfMovies = movieCollection.totalResults
                
                if(movieCollection.page > 1){
                let indexPathsToReload = self.computeIndexPathsToReload(from: movieCollection.fetchedMovies)
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
    
    
    func networkDownloadServiceCompletedDownload(atIndex indexOfDownload :Int, toLocation destinationURL :URL)
    {
        let thisMovie = movies[indexOfDownload]
          thisMovie.updateLocalImageUrl(updateUrl: destinationURL)
          
        DispatchQueue.main.async { [weak self] in
          self?.usersViewModelDelegate?.userModelUpdatedItem(atRow: indexOfDownload)
        }
    }
    
    
}
