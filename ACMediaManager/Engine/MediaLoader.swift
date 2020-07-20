//
//  MediaLoader.swift
//  WaynYo
//
//  Created by Hassan Moghnie on 3/8/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation

protocol MediaLoaderDelegate {
    func completed(mediaLoader: MediaLoader, error: Error?)
    func didReceive (mediaLoader: MediaLoader, data: Data)
    func onContentInformation (mediaLoader: MediaLoader, contentLength: Int64?, contentType: String?)
}

protocol MediaLoaderLifecycleDelegate {
    func didStop (mediaLoader: MediaLoader)
}
enum LoaderType {
    case Player
    case Downloader
    case Preheater
}

class MediaLoader: NSObject{
    
    class DataBuffer {
        let offset: Int64
        var data: Data
        
        init (offset: Int64, data: Data){
            self.offset = offset
            self.data = data
        }
    }
    
    var contentLength: Int64? {
        didSet{
            self.delegate.onContentInformation(mediaLoader: self, contentLength: self.contentLength, contentType: self.contentType)
        }
    }
    var contentType: String? {
        didSet{
            self.delegate.onContentInformation(mediaLoader: self, contentLength: self.contentLength, contentType: self.contentType)
        }
    }
    private let delegate: MediaLoaderDelegate
    var range: ByteRange?
    let key: String
    var task: URLSessionTask?
    let request: Any
    let urlSession: URLSession
    let url: URL
    var writeDataBuffer: DataBuffer?
    let media: Media?
    var readDataBuffer: Data?
    let type: LoaderType
    let lifecycleDelegate: MediaLoaderLifecycleDelegate
    
    func didReceive (data: Data){
        guard let writeBuffer = self.writeDataBuffer else {return}
        writeBuffer.data.append(data)
        if (writeBuffer.data.count > MediaCacheManager.WRITE_BUFFER_SIZE ){
            MediaCacheDBStorage.shared?.addFragment(mediaKey: key, offset: writeBuffer.offset, data: writeBuffer.data)
            self.writeDataBuffer = DataBuffer(offset: writeBuffer.offset + Int64(writeBuffer.data.count), data: Data())
        }
        self.delegate.didReceive(mediaLoader: self, data: data)
    }
    func completed (error: Error?){
        self.stop()
        self.delegate.completed(mediaLoader: self, error: error)
    }
    
    
    
    init (urlSession: URLSession, request: Any, url: URL, key: String, range: ByteRange,
          media: Media?, delegate: MediaLoaderDelegate, lifecycleDelegate: MediaLoaderLifecycleDelegate, type: LoaderType){
        self.range = range
        self.key = key
        self.delegate = delegate
        self.request = request
        self.urlSession = urlSession
        self.media = media
        self.url = url
        self.type = type
        self.lifecycleDelegate = lifecycleDelegate
        
        super.init()
        
        self.buildTask()
        
    }
    private func buildTask () {
        guard let neededRange = range else{
            return
        }
        if media == nil {
            var urlRequest = URLRequest(url: url)
            self.writeDataBuffer = DataBuffer(offset: neededRange.lowerBound, data: Data())
            print ("---- \(key) started url request for \(neededRange)")
            urlRequest.setByteRangeHeader(for: neededRange)
            let t = self.urlSession.dataTask(with: urlRequest)
            self.task = t
        }
        else{
            let cr = media?.getAvailableRange(requested: neededRange)
            //print ("\(key) media found -requested range \(neededRange) - cache response - \(String(describing: cr))")
            if let cacheResponse = cr {
                if let neededRange = cacheResponse.neededRange, neededRange.length > 0{
                    var urlRequest = URLRequest(url: url)
                    self.writeDataBuffer = DataBuffer(offset: neededRange.lowerBound, data: Data())
                    print ("---- \(key) started url request for \(neededRange)")
                    urlRequest.setByteRangeHeader(for: neededRange)
                    let t = self.urlSession.dataTask(with: urlRequest)
                    self.task = t
                }
            }
        }
    }
    func startTask () {
        
        guard let neededRange = range else{
            return
        }
        if let m = media {
            self.contentLength = m.contentLength
            self.contentType = m.mimeType
            delegate.onContentInformation(mediaLoader: self, contentLength: m.contentLength, contentType: m.mimeType)
            if let cacheResponse = m.getAvailableRange(requested: neededRange){
                if let availableRange = cacheResponse.availableRange,
                    self.type != .Preheater /*Ignore retrieving data when we are preheating. We don't need the data*/{
                    
                    if let assemblies = m.neededAssembly(range: availableRange){
                        self.readDataBuffer = Data()
                        assemblies.forEach{ assemblyInfo in
                            if let d = m.data(assembly: assemblyInfo) {
                                self.readDataBuffer?.append(d)
                            }
                            if let data = self.readDataBuffer, data.count > MediaCacheManager.READ_BUFFER_SIZE {
                                self.delegate.didReceive(mediaLoader: self, data: data)
                                self.readDataBuffer = Data()
                            }
                        }
                        if let data = self.readDataBuffer, data.count > 0{
                            self.delegate.didReceive(mediaLoader: self, data: data)
                        }
                    }
                }
                self.range = cacheResponse.neededRange
            }
        }
        
        if let t = self.task {
            t.resume()
        }
        else{
            self.completed(error: nil)
        }
        
    }
    func stop () {
        if let writeBuffer = self.writeDataBuffer, writeBuffer.data.count > 0{
            self.flushBuffer()
        }
        
        if let task = self.task {
            task.cancel()
        }
        
        lifecycleDelegate.didStop(mediaLoader: self)
    }
    func flushBuffer () {
        print ("key \(key) -- flushing data buffer")
        if let writeBuffer = self.writeDataBuffer, writeBuffer.data.count > 0{
            print ("key \(key) -- flushing \(writeBuffer.data.count)")
            
            MediaCacheDBStorage.shared?.addFragment(mediaKey: key, offset: writeBuffer.offset, data: writeBuffer.data)
        }
    }
}
