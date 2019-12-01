//
//  NetworkDownloadService.swift
//  CurveMovieExplorer
//
//  Created by Osagie Zogie-Odigie on 28/11/2019.
//  Copyright © 2019 Osagie Zogie-Odigie. All rights reserved.
//

import Foundation

protocol NetworkDownloadServiceProtocol {
    func networkDownloadServiceCompletedDownload(atIndex indexOfDownload :Int, toLocation destinationURL:URL)
}

class NetworkDownloadService :NSObject, URLSessionDownloadDelegate {

    var downloadsinProgress = [URL : Int]()
    var downloadsSession :URLSession?
    var networkDownloadServiceDelegate :NetworkDownloadServiceProtocol?
    
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier:"com.curvemovieexplorer.backgroundsession")
                    downloadsSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    /*
     When we start downloading an item we include its index in a dictionary with its URL as the key. This will enable us know which item initiated a download when it completes.
     */
    func startDownloading(resourceWithURL resourceUrl :URL, atIndex index :Int){
        
        downloadsSession?.downloadTask(with: resourceUrl).resume()
        downloadsinProgress[resourceUrl] = index
        
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
          
          let indexOfDownload = downloadsinProgress[sourceURL]
          
          guard indexOfDownload != nil else{
              return
          }
          
          downloadsinProgress[sourceURL] = nil
          let destinationURL = localFilePath(for: sourceURL)
          let fileManager = FileManager.default
          try? fileManager.removeItem(at: destinationURL)

          do {
            try fileManager.copyItem(at: location, to: destinationURL)
          } catch _ {
            return
          }
          
        networkDownloadServiceDelegate?.networkDownloadServiceCompletedDownload(atIndex: indexOfDownload!, toLocation: destinationURL)

    }
    
    func localFilePath(for url: URL) -> URL {
      return documentsPath.appendingPathComponent(url.lastPathComponent)
    }

}
