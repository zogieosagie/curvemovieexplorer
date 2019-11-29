//
//  ViewController.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 26/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import UIKit

class CurveExplorerViewController: UIViewController, CurveMovieExplorerViewModelProtocol, MovieOverviewTableCellProtocol, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {

    var curveExplorerViewModel :CurveMovieExplorerViewModel?
    
    @IBOutlet weak var moviesTableView: UITableView!
    @IBOutlet weak var errorMessageContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moviesTableView.rowHeight = UITableView.automaticDimension
        moviesTableView.estimatedRowHeight = 480
        
        curveExplorerViewModel?.fetchMovies()
        errorMessageContainer.layer.cornerRadius = 5.0
    }
    
    func configureController(withViewModel viewModel :CurveMovieExplorerViewModel){
        curveExplorerViewModel =  viewModel
        curveExplorerViewModel?.usersViewModelDelegate = self
    }
    
    //MARK: CurveExplorerViewModelProtocol methods
    func userViewModelUpdatedUsersList(with newIndexPathsToReload: [IndexPath]?, andErrorMessage errorMessage: String?) {
        
        if(errorMessage == nil)
        {
            errorMessageContainer.isHidden = true
            
            guard let newIndexPathsToReload = newIndexPathsToReload else {
              self.moviesTableView.reloadData()
              return
            }

            let indexPathsToReload = visibleIndexPathsToReload(intersecting: newIndexPathsToReload)
            self.moviesTableView.reloadRows(at: indexPathsToReload, with: .automatic)
        }
        else
        {
            errorMessageContainer.isHidden = false
            errorMessageLabel.text = errorMessage
        }
    }
    
    func userModelUpdatedItem(atRow row: Int) {
        self.moviesTableView.reloadRows(at: [IndexPath.init(row: row, section: 0)], with: .none)
    }
    
    //MARK: Tableview datasource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return curveExplorerViewModel?.numberOfMovies() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if dataIsStillLoading(for: indexPath)
        {
            let movieOverviewCell = moviesTableView.dequeueReusableCell(withIdentifier: "MovieOverviewLoadingTableCell")!
            
            return movieOverviewCell
        }
        else{
            let movieOverviewCell = moviesTableView.dequeueReusableCell(withIdentifier: "MovieOverviewTableCell") as! MovieOverviewTableCell
            
            movieOverviewCell.configureCell(forPosition: indexPath.row, withDelegate: self, cellWidth: self.view.frame.size.width)
            
            movieOverviewCell.movieTitle.text = curveExplorerViewModel?.movieTitle(forCellAtIndex: indexPath.row)
            movieOverviewCell.movieOverview.text = curveExplorerViewModel?.movieOverview(forCellAtIndex: indexPath.row)
            movieOverviewCell.voteAverage.text = curveExplorerViewModel?.voteAveragePercentString(forCellAtIndex: indexPath.row)
            movieOverviewCell.releaseDate.text = curveExplorerViewModel?.releaseDate(forCellAtIndex: indexPath.row)
            

            movieOverviewCell.isFavourite = curveExplorerViewModel?.favouriteStatus(forCellAtIndex: indexPath.row) ?? false
            
            movieOverviewCell.loadPosterImage(fromUrl :curveExplorerViewModel?.imagePath(forCellAtIndex: indexPath.row))
            
            return movieOverviewCell
        }
    }
    
    //MARK: Tableview delegate
    func cellRequestsToggleFavourites(atPosition index: Int?) {
        curveExplorerViewModel?.toggleFavouriteRequest(forItem: index!)
    }
    
    //MARK: Tableview prefetch delegate
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
      if indexPaths.contains(where: dataIsStillLoading) {
        curveExplorerViewModel?.fetchMovies()
      }
    }
    
    func dataIsStillLoading(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= curveExplorerViewModel!.currentCount()
    }
    
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
      let indexPathsForVisibleRows = moviesTableView.indexPathsForVisibleRows ?? []
      let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
      return Array(indexPathsIntersection)
    }

}

