//
//  MediaCacheDBStorage.swift
//  CachingVideoTest
//
//  Created by Hassan Moghnie on 1/5/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation
import ObjectBox
import SwifterSwift
import Schedule

// objectbox:Entity
class MediaDA{
    
    var id: Id = 0 // An ID is required by ObjectBox
    
    // objectbox: unique
    var key: String
    
    // objectbox: index
    var createdOn: Date = Date()
    
    var mimeType: String?
    
    var contentLength: Int64?
    
    // objectbox: backlink = "media"
    var fragments: ToMany<MediaFragmentDA> = nil
    
    required init (){
        self.key = ""
    }
    convenience init(key: String) {
        self.init()
        self.key = key
    }
}
// objectbox:Entity
class MediaFragmentDA {
    var id: Id = 0
    
    var offset: Int64
    var length: Int64
    
    // objectbox: index
    var key: String
    
    var media: ToOne<MediaDA> = nil
    
    required init(){
        offset = 0
        length = 0
        key = ""
    }
    
    convenience init (key: String, offset: Int64, length: Int64){
        self.init()
        self.key = key
        self.offset = offset
        self.length = length
    }
}
class MediaCacheDBStorage {
    static let MAX_CACHE_SIZE = 500 * 1024 * 1024
    
    let store: Store
    private let fileManager = FileManager.init()
    let cacheDirectory: URL
    
    public static let shared = MediaCacheDBStorage()
    let writeQueue = DispatchQueue.init(label: "dbWriteQueue", qos: .background)
    
    var task: Task?
    let dispatchQueue = DispatchQueue(label: "LocalDbManager")
    
    
    public func findMedia (mediaKey: String, autoCreate: Bool = false) -> MediaDA?{
        let mediaBox = store.box(for: MediaDA.self)
        let query: Query<MediaDA>? = try? mediaBox.query{
            MediaDA.key == mediaKey
        }.build()
        var media = try? query?.find().first
        if !autoCreate || media != nil{
            return media
        }
        
        writeQueue.sync(flags: .barrier) {
            media = try? query?.find().first
            if media == nil{
                media = MediaDA(key: mediaKey)                
                _ = try? mediaBox.put(media!)
            }
        }
        return media
    }
    
    public func addFragment (mediaKey: String, offset: Int64, data: Data){
        guard let media = findMedia(mediaKey: mediaKey, autoCreate: true) else{
            return
        }
        
        writeQueue.async{
            let fragmentBox = self.store.box(for: MediaFragmentDA.self)
            let key = UUID().uuidString
            let fragment = MediaFragmentDA(key: key, offset: offset, length: Int64(data.count))
            var fragmentId: Id?
            
            do{
                fragment.media.target = media
                fragmentId = try fragmentBox.put(fragment)
                
            }
            catch{
                return
            }
            do{
                let url = self.cacheDirectory.appendingPathComponent(mediaKey, isDirectory: true).appendingPathComponent(fragment.key)
                _ = self.fileManager.createSubdirectory(mediaKey, atUrl: self.cacheDirectory)
                try data.write(to: url)
            }
            catch{
                if let id = fragmentId{
                    _ = try? fragmentBox.remove(id)
                }
            }
        }
        
    }
    public func data (fragment: MediaFragment) -> Data?{
        let url = self.cacheDirectory.appendingPathComponent(fragment.mediaKey, isDirectory: true).appendingPathComponent(fragment.key)
        return try? Data(contentsOf: url)
    }
    public func findMediaDto(key: String, autoCreate: Bool = false) -> Media? {
        var result: Media?
        if let media = self.findMedia(mediaKey: key, autoCreate: autoCreate) {
            result = Media(key: key)
            result?.contentLength = media.contentLength
            result?.mimeType = media.mimeType
            media.fragments.forEach{fragment in
                let f = MediaFragment (mediaKey: key, offset: fragment.offset, length: fragment.length, key: fragment.key)
                result?.addInfo(info: f)
            }
        }
        return result
    }
    public func setMediaInfo (mediaKey: String, contentLength: Int64, mimeType: String?){
        
        guard let m = self.findMedia(mediaKey: mediaKey, autoCreate: true) else {
            return
        }
        
        writeQueue.sync (flags: .barrier) {
            
            let mediaBox = self.store.box(for: MediaDA.self)
            guard let media = try? mediaBox.get(m.id) else{
                return
            }
            if contentLength > 0{
                media.contentLength = contentLength
            }
            if let mt = mimeType{
                media.mimeType = mt
            }
            do{
                let id = try mediaBox.put(media)
                print ("key \(mediaKey) set media info \(contentLength) \(String(describing: mimeType)) - id \(id)")
            }
            catch {
                print ("key \(mediaKey) set media info \(contentLength) \(String(describing: mimeType)) - error \(error)")
            }
        }
    }
    private init(){
        let dbFile = (fileManager.documentsDirectory()?.appendingPathComponent("VLMediaCacheManagerDB"))!
        store = try! Store(directoryPath: dbFile.path, maxDbSizeInKByte: 100_000)
        cacheDirectory = (fileManager.documentsDirectory()?.appendingPathComponent("VLMediaCacheManager"))!
        
        self.task = Plan.every(10.minutes).do(queue: dispatchQueue, action:{
            self.checkLimit()
        }
        )
    }
    private func delete (media: MediaDA) {
        let mediaBox = self.store.box (for: MediaDA.self)
        let fragmentBox = self.store.box (for: MediaFragmentDA.self)
        
        let url = self.cacheDirectory.appendingPathComponent(media.key, isDirectory: true)
        if fileManager.removeDirectory(url){
            print ("Directory \(url.description) deleted")
            do{
                try fragmentBox.remove(media.fragments)
                try mediaBox.remove (media)
            }
            catch {
                print ("deleting media \(media.key) error \(error)")
            }
        }
    }
    public func checkLimit () {
        do{
            var size = try fileManager.allocatedSizeOfDirectory(at: cacheDirectory)
            print ("Cache DB Size = \(size.formattedWithSeparator)")
            if (size > MediaCacheDBStorage.MAX_CACHE_SIZE) {
                var date = Date()
                date.add(.minute, value: -10)
                
                let mediaBox = self.store.box (for: MediaDA.self)
                let query: Query<MediaDA>? = try? mediaBox.query{
                    MediaDA.createdOn.isBefore(date)
                }.ordered(by: MediaDA.createdOn).build()
                //var totalSize: UInt64 = 0
                if let expiredMedias = try? query?.find() {
                    for media in expiredMedias
                    {
//                        let url = self.cacheDirectory.appendingPathComponent(media.key, isDirectory: true)
//                        size = try fileManager.allocatedSizeOfDirectory(at: url)
//                        totalSize = totalSize + size
//                        print ("size of \(media.key) directory is \(size.formattedWithSeparator)")
                        print ("deleting \(media.key) -- \(media.createdOn) - resulting size \(size)")
                        self.delete(media: media)
                        size = try fileManager.allocatedSizeOfDirectory(at: cacheDirectory)
                        print ("deleted \(media.key) -- \(media.createdOn) - resulting size \(size)")
                        if (size < MediaCacheDBStorage.MAX_CACHE_SIZE){
                            break
                        }
                    }
                    
                }
                //print ("******** calculated total size from media \(totalSize.formattedWithSeparator)")
            }
        }
        catch {}
        
    }
    public func removeExpired (before: Date){
        
        let mediaBox = self.store.box (for: MediaDA.self)
        let query: Query<MediaDA>? = try? mediaBox.query{
            MediaDA.createdOn.isBefore(before)
        }.build()
        
        if let expiredMedias = try? query?.find() {
            expiredMedias.forEach{ media in
                print ("Deleting media \(media.key)")
                self.delete(media: media)
            }
            
        }
    }
    
    public func test(){
        let mediaBox = store.box(for: MediaDA.self)
        let fragmentBox = store.box(for: MediaFragmentDA.self)
        let media = MediaDA(key: "12345")
        do{
            let id = try mediaBox.put(media)
            print ("put \(media) id is \(id)")
        }
        catch{
            
        }
        
        
        try? mediaBox.all().forEach{media in
            print (media.key)
            media.fragments.forEach{
                print ($0.key)
            }
            
        }
        
        let query: Query<MediaDA>? = try? mediaBox.query {
            MediaDA.key == "12345"
        }.build()
        if let media = try? query?.find().first {
            let fragment = MediaFragmentDA(key: "xxxxx", offset: 0, length: 10)
            fragment.media.target = media
            try? fragmentBox.put(fragment)
        }
        
    }
    
}
