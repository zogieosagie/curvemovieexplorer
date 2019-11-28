//
//  Movie.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 28/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import Foundation

class Movie : Codable {
    let movieTitle :String
    let imagePath :String
    let releaseDate :String
    let movieOverview :String
    let voteAverage :Double?
    
    var isFavourite = false
    var localImageUrl :URL?
    
    func updateLocalImageUrl(updateUrl :URL) {
        self.localImageUrl = updateUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case movieTitle = "title"
        case imagePath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case movieOverview = "overview"
    }
}
