//
//  NetworkDownloadService.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 28/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import Foundation

class NetworkDownloadService {
    var downloadsinProgress = [URL : Int]()
    var downloadsSession :URLSession?
    
    init(withDelegate delegate :URLSessionDelegate?) {
        let config = URLSessionConfiguration.background(withIdentifier:"com.stackOverflowUsers.backgroundsession")
                    downloadsSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }
    
    /*
     When we start downloading an item we include its index in a dictionary with its URL as the key. This will enable us know which item initiated a download when it completes.
     */
    func startDownloading(resourceWithURL resourceUrl :URL, atIndex index :Int){
        
        downloadsSession?.downloadTask(with: resourceUrl).resume()
        downloadsinProgress[resourceUrl] = index
        
    }
}
