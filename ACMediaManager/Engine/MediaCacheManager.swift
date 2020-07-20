//
//  MediaCacheManager.swift
//  MediaCacheTest
//
//  Created by Hassan Moghnie on 1/8/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation
import AVFoundation
import CoreData


class MediaCacheResponse: Equatable{
    static func == (lhs: MediaCacheResponse, rhs: MediaCacheResponse) -> Bool {
        return lhs.availableRange == rhs.availableRange && lhs.neededRange == rhs.neededRange
    }
    
    var availableRange: ByteRange?
    var neededRange: ByteRange?
    
    convenience init(availableRange: ByteRange?, neededRange: ByteRange?) {
        self.init()
        self.availableRange = availableRange
        self.neededRange = neededRange
    }
    public func description() -> String {
        return "\(self) - availableRange (\(String(describing: availableRange))) : neededRange(\(String(describing: neededRange)))"
    }
}

class MediaFragmentAssembly{
    let mediaFragment: MediaFragment
    let usedRange: ByteRange
    init (mediaFragement: MediaFragment, usedRange: ByteRange){
        self.mediaFragment = mediaFragement
        self.usedRange = usedRange
    }
    public func description() -> String{
        "\(mediaFragment.key) used range \(usedRange)"
    }
}



public class MediaCacheManager: NSObject, MediaLoaderLifecycleDelegate {
    func didStop(mediaLoader: MediaLoader) {
        if let task = mediaLoader.task {
            self.loaders.remove(task: task)        
        }
    }
    
    
    static let WRITE_BUFFER_SIZE = 1024 * 1024
    static let READ_BUFFER_SIZE = 1024 * 1024
    static let firstTwoBytes = Int64(0)..<Int64(2)
    static let MAX_PREHEAT_HEADER = 1024 * 1024 * 2
    static let MAX_PREHEAT_TAIL = 1024 * 512
    static let FIRST_TWO_BYTES = Int64(2)
    
    
    var urlSession: URLSession?
    
    private let backgroundQueue = DispatchQueue.init(label: "BGMediaCahcheManager", qos: .background, attributes: .concurrent)
    private let defaultQueue = DispatchQueue.init(label: "DMediaCacheManager", qos: .default, attributes: .concurrent)
    let serialQueue = DispatchQueue(label: "queuename")
    
    public static let shared = MediaCacheManager(maxOperations: 2)
    //    public static let downloader = MediaCacheManager(maxOperations: 1)
    //    public static let preheater = MediaCacheManager(maxOperations: 1)
    
    var loaders = MediaLoaders()
    
    
    init(maxOperations: Int){
        super.init()
        let config = URLSessionConfiguration.default
        //        let operationQueue = OperationQueue()
        //        operationQueue.maxConcurrentOperationCount = maxOperations
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    public static func initDBPrivider(){
        MediaCacheDBStorage.initDBStorage()
    }
}


extension MediaCacheManager: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate{
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let loader = self.loaders.find(task: task) {
            loader.completed(error: error)
        }
    }
    
    // MARK: - URLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        var contentLength = response.expectedContentLength
        let mimeType = response.mimeType
        if let httpResponse = response as? HTTPURLResponse {
            if let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String{
                if let length = Int64(contentRange.components(separatedBy: "/")[1]) {
                    contentLength = length
                }
            }
        }
        
        if let loader = self.loaders.find(task: dataTask) {
            loader.contentLength = contentLength
            loader.contentType = mimeType
            MediaCacheDBStorage.shared?.setMediaInfo(mediaKey: loader.key, contentLength: contentLength, mimeType: mimeType)
        }
        
        //       MediaCacheManager.shared.setMediaInfo(mediaKey: self.mediaKey, contentLength: contentLength, mimeType: mimeType, redirectUrl: response.url?.absoluteString)
        //Loader.processResponse(loadingRequest: loadingRequest, infoResponse: response)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print ("data task \(dataTask) received --- \(data.count) bytes")
        
        if let loader = self.loaders.find(task: dataTask) {
            loader.didReceive(data: data)
        }
        else {
            print ("********** received data, can't find a loader ********")
        }
    }
    
    public func findMedia (key: String, autoCreate: Bool = false) -> Media?{
        return MediaCacheDBStorage.shared?.findMediaDto(key: key, autoCreate: autoCreate)
    }
    
    public func stop(key: String){
        backgroundQueue.async {
            if let loaders = self.loaders.findByMediaKeyAndType(key: key, type: .Player){
                for loader in loaders {
                    print ("loader \(key), cancel task \(String(describing: loader.task))")
                    loader.stop()
                }
            }

        }
    }
    public func stop (key: String, request: AVAssetResourceLoadingRequest){
        backgroundQueue.async {
            if let loaders = self.loaders.findByMediaKeyAndType(key: key, type: .Player){
                for loader in loaders {
                    if let r = loader.request as? AVAssetResourceLoadingRequest, r == request{
                        loader.stop()
                    }
                }
            }

        }
    }
    func stop(key: String, type: LoaderType){
        if let loaders = self.loaders.findByMediaKeyAndType(key: key, type: type){
            for loader in loaders {
                print ("loader \(key), cancel task \(String(describing: loader.task))")
                loader.stop()
            }
        }
    }
    
    func request(request: Any, url: URL, key: String, range: ByteRange, delegate: MediaLoaderDelegate, type: LoaderType) -> MediaLoader?{
        guard let urlSession = self.urlSession else {
            fatalError()
        }
        
        let object = self.findMedia(key: key)
        
        var loader: MediaLoader?
        
        serialQueue.sync {
            loader = MediaLoader (urlSession: urlSession, request: request, url: url, key: key, range: range, media: object, delegate: delegate, lifecycleDelegate: self, type: type)
            if let preheatLoaders = self.loaders.findByMediaKeyAndType(key: key, type: .Preheater){
                for loader in preheatLoaders {
                    loader.task?.cancel()
                }
            }
            if let l = loader, let task = l.task {
                self.loaders.add(task: task, mediaLoader: l)
            }
            else{
                return
            }
        }
        
        
        self.defaultQueue.async {
            loader?.startTask()
        }
        
        return loader
        
    }
    func preheat (url: URL, key: String, range: ByteRange? = nil, delegate: MediaLoaderDelegate? = nil) {
        //check if this key is already beign loaded or preheated
        
        print ("preheating -- \(key)")
        let requestedRange = range ?? MediaCacheManager.firstTwoBytes
        guard let urlSession = self.urlSession else {
            fatalError()
        }
        let object = self.findMedia(key: key)
        
        var loader: MediaLoader?
        
        serialQueue.sync {
            if let loaders = self.loaders.findByMediaKey(key: key), loaders.count > 0 {
                print ("preheating -- \(key) found loader with the same key")
                self.loaders.printAll()
                return
            }
            loader = MediaLoader (urlSession: urlSession, request: self.request, url: url, key: key, range: requestedRange,
                                      media: object, delegate: delegate ?? PreheatMediaDelegate(), lifecycleDelegate: self, type: .Preheater)
            if let l = loader, let task = l.task {
                self.loaders.add(task: task, mediaLoader: l)
            }
            else{
                return
            }
        }
        
        
        self.backgroundQueue.async {
            
            loader?.startTask()
        }
    }
//    public func export (with url: URL, key: String, range: ByteRange?, exportHandler: @escaping ExportCompletion, delegate: MediaLoaderDelegate? = nil) {
//        print ("exporting key \(key)")
//
//        guard let urlSession = self.urlSession else {
//            fatalError()
//        }
//        let requestedRange = range ?? MediaCacheManager.firstTwoBytes
//        let object = self.findMedia(key: key)
//        
//        var loader: MediaLoader?
//        
//        serialQueue.sync {
//            loader = MediaLoader (urlSession: urlSession, request: request, url: url, key: key, range: requestedRange, media: object, delegate: delegate ?? ExportMediaDelegate(exportHandler: exportHandler), lifecycleDelegate: self, type: .Downloader)
//            if let l = loader, let task = l.task {
//                self.loaders.add(task: task, mediaLoader: l)
//            }
//            else{
//                return
//            }
//        }
//        
//        
//        self.backgroundQueue.async {
//            loader?.startTask()
//        }
//    }
}

class PreheatMediaDelegate: MediaLoaderDelegate {
    
    enum State {case first; case second; case third}
    
    var state: State = .first
    
    func completed(mediaLoader: MediaLoader, error: Error?) {        
        if error != nil{
            return
        }
        print ("Preheating \(mediaLoader.key) -- contentLength \(String(describing: mediaLoader.contentLength!))")
        switch (state){
        case .first:
            state = .second
            if let contentLength = mediaLoader.contentLength {
                var requestedLength = contentLength
                if (contentLength > MediaCacheManager.MAX_PREHEAT_HEADER){
                    requestedLength = Int64(MediaCacheManager.MAX_PREHEAT_HEADER)
                }
                print ("Preheating key \(mediaLoader.key), from = 0 -- to = \(requestedLength)")
                MediaCacheManager.shared.preheat(url: mediaLoader.url, key: mediaLoader.key,
                                                 range: (Int64.zero ..< requestedLength), delegate: self)
            }
            
        case .second:
            state = .third
            if let contentLength = mediaLoader.contentLength {
                let lastBytes = contentLength - Int64(MediaCacheManager.MAX_PREHEAT_TAIL)
                print ("Preheating key \(mediaLoader.key), from = \(lastBytes) -- to = \(contentLength)")
                if lastBytes > 0 {
                    MediaCacheManager.shared.preheat(url: mediaLoader.url, key: mediaLoader.key,
                                                     range: (lastBytes ..< contentLength), delegate: self)
                }
            }
        case .third:
            break
        }
    }
    
    func didReceive(mediaLoader: MediaLoader, data: Data) {
        print ("prehating key \(mediaLoader.key) -- received \(data.count) bytes")
    }
    
    func onContentInformation(mediaLoader: MediaLoader, contentLength: Int64?, contentType: String?) {
    }
    
    
}
//class ExportMediaDelegate : MediaLoaderDelegate{
//
//
//    var exportHandler: ExportCompletion
//    //var fileHandle: FileHandle?
//    var receivedDataCount: Int64 = 0
//    var data = Data()
//
//    enum State {case waitingForHeader; case waitingForRest}
//
//    var state: State = .waitingForHeader
//
//    init (exportHandler: @escaping ExportCompletion){
//        self.exportHandler = exportHandler
//    }
//
//    func completed(mediaLoader: MediaLoader, error: Error?) {
//
//        if let e = error {
//            print ("exporting \(mediaLoader.key) failed to export file \(e.localizedDescription)")
//            exportHandler(.failed(message: "Failed to download media".localized()))
//            return
//        }
//        switch  (state) {
//        case .waitingForHeader:
//            self.state = .waitingForRest
//            guard let contentLength = mediaLoader.contentLength else{
//                exportHandler(.failed(message: "Invalid media"))
//                return
//            }
//            MediaCacheManager.shared.export(with: mediaLoader.url, key: mediaLoader.key,
//                                            range: Int64.zero..<contentLength,
//                                            exportHandler: self.exportHandler, delegate: self)
//        case .waitingForRest:
//            //            if let handle = fileHandle{
//            //                handle.seekToEndOfFile()
//            //                handle.closeFile()
//            //                self.fileHandle = nil
//            //                if let urlString = result, let url = URL(string: urlString){
//            //                    exportHandler(.completedVideo(key: mediaLoader.key, url: url))
//            //                }
//            //            }
//            do{
//                let url = Utils.randomFile(type: ".mp4")
//                try data.write(to: url)
//                exportHandler(.completedVideo(key: mediaLoader.key, url: url))
//            }
//            catch{
//                exportHandler(.failed(message: "Failed to save file".localized()))
//                print ("exporting \(mediaLoader.key) error \(error)")
//            }
//
//        }
//
//
//    }
//
//    func didReceive(mediaLoader: MediaLoader, data: Data) {
//        switch state {
//        case .waitingForRest:
//            //            if fileHandle == nil{
//            //                self.result = Utils.randomFileName(type: "") //TODO mp4!!!
//            //                if let urlString = self.result, let url = URL(string: urlString) {
//            //                    do{
//            //                        FileManager.default.createFile(atPath: urlString, contents: nil, attributes: [FileAttributeKey.extensionHidden: true])
//            //                        fileHandle = try FileHandle.init(forWritingTo: url)
//            //                    }
//            //                    catch{
//            //                        print ("Failed to create a file \(error)")
//            //                    }
//            //                }
//            //            }
//            //            if let handle = fileHandle {
//            //                receivedDataCount = receivedDataCount.advanced(by: data.count)
//            //                if let contentLength = mediaLoader.contentLength {
//            //                    exportHandler(.downloading(progress: (receivedDataCount.toInt().float / contentLength.toInt().float)))
//            //                }
//            //                handle.seekToEndOfFile()
//            //                handle.write(data)
//            //            }
//            //            else{
//            //                exportHandler(.failed(message: "Cannot create file".localized()))
//            //            }
//            self.data.append(data)
//            receivedDataCount = receivedDataCount.advanced(by: data.count)
//            print ("exporting received data count \(receivedDataCount)")
//            if let contentLength = mediaLoader.contentLength {
//                let progress = (receivedDataCount.toInt().float / contentLength.toInt().float)
//                print ("download progress \(progress)")
//                exportHandler(.downloading(progress: progress))
//            }
//
//        default:
//            break
//        }
//    }
//
//    func onContentInformation(mediaLoader: MediaLoader, contentLength: Int64?, contentType: String?) {
//
//    }
//
//
//}
