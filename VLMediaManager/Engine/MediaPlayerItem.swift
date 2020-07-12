//
//  MediaPlayerItem.swift
//  MediaCacheTest
//
//  Created by Hassan Moghnie on 1/13/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//


import Foundation
import AVFoundation

class MediaPlayerItem : AVPlayerItem{
    
    static let WRITE_BUFFER_SIZE = 1024 * 1024
    
    class DataBuffer {
        let offset: Int64
        var data: Data
        
        init (offset: Int64, data: Data){
            self.offset = offset
            self.data = data
        }
    }
    
    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, MediaLoaderDelegate {
        func didReceive(mediaLoader: MediaLoader, data: Data) {
            if let request = mediaLoader.request as? AVAssetResourceLoadingRequest{
                                DispatchQueue.main.async {
                print ("request - \(mediaLoader.key) - responded with \(data.count) bytes")
                request.dataRequest?.respond(with: data)
                }
            }
        }
        
        func completed(mediaLoader: MediaLoader, error: Error?) {
            print ("MediaPlayerItem completed ")
            if let request = mediaLoader.request as? AVAssetResourceLoadingRequest{
                DispatchQueue.main.async {
                    if let cl = self.contentLength, let ct = self.contentType{
                        request.contentInformationRequest?.contentLength = cl
                        request.contentInformationRequest?.contentType = ct
                        print("request \(mediaLoader.key) -- finished")
                        request.finishLoading()
                    }
                }
            }
        }
        
        func onContentInformation(mediaLoader: MediaLoader, contentLength: Int64?, contentType: String?) {
            print ("MediaPlayerItem onContentInformation \(String(describing: contentLength)) -- \(String(describing: contentType))")
            if let cl = contentLength{
                self.contentLength = cl
            }
            if let ct = contentType{
                self.contentType = ct
            }
            if let cl = contentLength, let ct = contentType {
                if let request = mediaLoader.request as? AVAssetResourceLoadingRequest{
                    DispatchQueue.main.async {
                        request.contentInformationRequest?.contentLength = cl
                        request.contentInformationRequest?.contentType = ct
                    }
                }

            }
        }
        
                  
        let id = UUID().uuidString
        
        private static let SchemeSuffix = "-demoloader"
        
        // MARK: - Properties
        // MARK: Public
                
        lazy var streamingAssetURL: URL = {
            guard var components = URLComponents(url: self.url, resolvingAgainstBaseURL: false) else {
                fatalError()
            }
            components.scheme = (components.scheme ?? "") + ResourceLoaderDelegate.SchemeSuffix
            guard let retURL = components.url else {
                fatalError()
            }
            print ("Streaming url \(retURL)")
            return retURL.appendingPathExtension("mp4")
        }()
        
        private let url: URL
        private var requestToLoader = [AVAssetResourceLoadingRequest : MediaLoader]()
        
        private var mediaKey: String
        weak var owner: MediaPlayerItem?
        var contentLength: Int64?
        var contentType: String?
        
        // MARK: - Life Cycle Methods
        
        init(withURL url: URL, key: String) {
            self.url = url
            self.mediaKey = key
        }
        
        // MARK: - Public Methods
                
        
        
        // MARK: - AVAssetResourceLoaderDelegate
        
        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
                        
            //        if let response = Loader.response{
            //            Loader.processResponse(loadingRequest: loadingRequest, infoResponse: response)
            //        }
            //print ("------->loading request \(loadingRequest)")
            if let contentInformationRequest = loadingRequest.contentInformationRequest{
                if let contentLength = self.contentLength {
                    contentInformationRequest.contentLength = contentLength
                }
                if let contentType = self.contentType {
                    contentInformationRequest.contentType = contentType
                }
            }
            if let dataRequest = loadingRequest.dataRequest{
                if let loader = MediaCacheManager.shared.request(request: loadingRequest, url: self.url, key: mediaKey, range: dataRequest.byteRange, delegate: self, type: .Player){
                    requestToLoader[loadingRequest] = loader
                }
            }
            
            return true
        }
        
        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
            print ("did cancel<-------- loading request \(loadingRequest)")
            if let loader = requestToLoader[loadingRequest] {
                loader.stop()
                requestToLoader.removeValue(forKey: loadingRequest)
            }
        }
        deinit {
            self.requestToLoader.forEach{key, value in
                value.stop()
            }
            requestToLoader.removeAll()
            print ("\(id) ************* deinit")
        }
    }
    
    //AVPlayer
    fileprivate let resourceLoaderDelegate: ResourceLoaderDelegate?
    let mediaKey: String
    init (url: URL, key: String){
        self.mediaKey = key
        self.resourceLoaderDelegate = ResourceLoaderDelegate(withURL: url, key: key)
        let asset = AVURLAsset(url: self.resourceLoaderDelegate!.streamingAssetURL)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        resourceLoaderDelegate?.owner = self
    }
    
    
}

extension MediaPlayerItem {
    static public func ==(rhs: MediaPlayerItem, lhs: MediaPlayerItem) -> Bool {
        return rhs.mediaKey == lhs.mediaKey
    }
}
