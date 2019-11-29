//
//  CurveMovieExplorerTests.swift
//  CurveMovieExplorerTests
//
//  Created by Osagie Zogie-Odigie on 26/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import XCTest
@testable import CurveMovieExplorer

class CurveMovieExplorerTests: XCTestCase {
    
    var systemUnderTest: CurveMovieExplorerViewModel!
    
    override func setUp() {
        
      super.setUp()
        systemUnderTest = CurveMovieExplorerViewModel.init(withMovies: mockMovies())
    }
    
    override func tearDown() {
      systemUnderTest = nil
      super.tearDown()
    }
    
    func testFavouritesToggling(){
        systemUnderTest.toggleFavouriteRequest(forItem: 0)
        XCTAssertTrue(systemUnderTest.favouriteStatus(forCellAtIndex: 0), "Failed: Expected favourite Status for user to be true")
        
        systemUnderTest.toggleFavouriteRequest(forItem: 0)
        XCTAssertFalse(systemUnderTest.favouriteStatus(forCellAtIndex: 0), "Failed: Expected favourite Status for user to be false")
    }
    
    func testVoteAveragePercentStringCreation(){
        let voteAverageString = systemUnderTest.voteAveragePercentString(forCellAtIndex: 0)
        XCTAssertEqual(voteAverageString, "76.0%", "Failed: Expected created percent string to be 76.0%")
    }
    
    
    func mockMovies() -> [Movie] {
        let jsonString = """
        {
            "title": "Spider-Man: Far from Home",
            "poster_path": "/5myQbDzw3l8K9yofUXRJ4UTVgam.jpg",
            "release_date": "2019-06-28",
            "overview": "Peter Parker and his friends go on a summer trip",
            "vote_average": 7.6
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        let mockMovie = try! JSONDecoder().decode(Movie.self, from: jsonData)
        let mockMovies = [mockMovie]
        
        return mockMovies
    }

}
