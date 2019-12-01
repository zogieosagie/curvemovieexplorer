//
//  MovieCollection.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 01/12/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import Foundation

struct MovieCollection :Codable {
    var fetchedMovies :[Movie]
    let totalResults :Int
    let page :Int
    
    enum CodingKeys: String, CodingKey {
        case fetchedMovies = "results"
        case totalResults = "total_results"
        case page = "page"
    }
}
