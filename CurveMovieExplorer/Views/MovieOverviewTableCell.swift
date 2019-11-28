//
//  MovieOverviewTableCell.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 28/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import UIKit

protocol MovieOverviewTableCellProtocol {
    func cellRequestsToggleFavourites(atPosition index:Int?)
}

class MovieOverviewTableCell: UITableViewCell {

    let kImageBorder :CGFloat = 30.0//Right and left border for image
    
    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var voteAverage: UILabel!
    @IBOutlet weak var releaseDate: UILabel!
    @IBOutlet weak var movieOverview: UILabel!
    
    @IBOutlet weak var favouritesButton: UIButton!
    
    @IBOutlet weak var mainContentBackground: UIView!
    
    
    var movieOverviewCellDelegate :MovieOverviewTableCellProtocol?
    var myIndex :Int?
    

    
    var isFavourite :Bool = false{
        
        didSet{
            if(isFavourite == true){
                let favouriteImage = UIImage(systemName: "suit.heart.fill", withConfiguration: .none)
                favouritesButton.tintColor = UIColor.red
                favouritesButton.setImage(favouriteImage, for: .normal)
            }
            else{
                let favouriteImage = UIImage(systemName: "suit.heart", withConfiguration: .none)
                favouritesButton.tintColor = UIColor.white
                favouritesButton.setImage(favouriteImage, for: .normal)
            }
        }
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func requestToToggleFavourite (_ sender: UIButton)
    {
        self.movieOverviewCellDelegate?.cellRequestsToggleFavourites(atPosition: myIndex)
    }
    
    
    func configureCell(forPosition position :Int, withDelegate delegate :MovieOverviewTableCellProtocol?, cellWidth width:CGFloat)
    {
        myIndex = position
        movieOverviewCellDelegate = delegate
        
        if((position % 2) > 0)
        {
            mainContentBackground.backgroundColor = UIColor.black
        }
        else
        {
            mainContentBackground.backgroundColor = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
        }
        
        let imageCornerRadius = (width - 2*kImageBorder)/2
        posterImage.layer.cornerRadius = imageCornerRadius
    }
    
    func loadPosterImage(fromUrl url :URL?){
        
        if let urlToLoad = url{
            let data = try? Data(contentsOf: urlToLoad)
            posterImage.image = UIImage(data: data!)
        }
    }

}
