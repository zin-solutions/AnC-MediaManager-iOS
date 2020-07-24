//
//  MediaCacheDBStorage.swift
//  CachingVideoTest
//
//  Created by Hassan Moghnie on 1/5/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation
//import ObjectBox
//import SwifterSwift
//import Schedule
import CoreData

// objectbox:Entity
//class MediaDA{
//
//    var id: Id = 0 // An ID is required by ObjectBox
//
//    // objectbox: unique
//    var key: String
//
//    // objectbox: index
//    var createdOn: Date = Date()
//
//    var mimeType: String?
//
//    var contentLength: Int64?
//
//    // objectbox: backlink = "media"
//    var fragments: ToMany<MediaFragmentDA> = nil
//
//    required init (){
//        self.key = ""
//    }
//    convenience init(key: String) {
//        self.init()
//        self.key = key
//    }
//}
// objectbox:Entity
//class MediaFragmentDA {
//    var id: Id = 0
//
//    var offset: Int64
//    var length: Int64
//
//    // objectbox: index
//    var key: String
//
//    var media: ToOne<MediaDA> = nil
//
//    required init(){
//        offset = 0
//        length = 0
//        key = ""
//    }
//
//    convenience init (key: String, offset: Int64, length: Int64){
//        self.init()
//        self.key = key
//        self.offset = offset
//        self.length = length
//    }
//}
class MediaCacheDBStorage {
    static let MAX_CACHE_SIZE = 500 * 1024 * 1024
    
    //    let store: Store
    private let fileManager = FileManager.init()
    let cacheDirectory: URL
    
    public static var shared:MediaCacheDBStorage?
    public static func initDBStorage(){
        shared = MediaCacheDBStorage()
    }
    
    //    let writeQueue = DispatchQueue.init(label: "dbWriteQueue", qos: .background)
    
    //    var task: Task?
    //    let dispatchQueue = DispatchQueue(label: "LocalDbManager")
    
    let persistentStoreCoordinator:NSPersistentStoreCoordinator
    let mediaManagerManagedObjectModel:NSManagedObjectModel
    let context:NSManagedObjectContext
    
    
    public func findMedia (mediaKey: String, autoCreate: Bool = false) -> Media?{
        print("findMedia")
        var media = Media.fetch(findByKey: mediaKey, context: context)
        if !autoCreate || media != nil{
            return media
        }
        
        print("findMedia -- writeQueue")
        media = Media.fetch(findByKey: mediaKey, context: context)
        if media == nil{
            media = Media(key: mediaKey, context: context)
            try? context.save()
        }
        
        return media
    }
    
    public func addFragment (mediaKey: String, offset: Int64, data: Data){
        print("addFragment")
        
        guard let media = findMedia(mediaKey: mediaKey, autoCreate: true) else{
            return
        }
        print("addFragment -- writeQueue")
        //            let fragmentBox = self.store.box(for: MediaFragmentDA.self)
        let key = UUID().uuidString
        let fragment = MediaFragment(mediaKey: key, offset: offset, length: Int64(data.count), context: context)
        
        do{
            fragment.media = media
            try context.save()
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
            context.delete(fragment)
            try? context.save()
        }
    }
    public func data (fragment: MediaFragment) -> Data?{
        let url = self.cacheDirectory.appendingPathComponent(fragment.mediaKey!, isDirectory: true).appendingPathComponent(fragment.key)
        return try? Data(contentsOf: url)
    }
    public func findMediaDto(key: String, autoCreate: Bool = false) -> Media? {
        var result: Media?
        if let media = self.findMedia(mediaKey: key, autoCreate: autoCreate) {
            result = Media(key: key, context: context)
            result?.contentLength = media.contentLength
            result?.mimeType = media.mimeType
            let mediaFragments: [MediaFragment] = (media.mediaFragments?.toArray())!
            mediaFragments.forEach{fragment in
                let f = MediaFragment(mediaKey: key, offset: fragment.offset, length: fragment.length, key: fragment.key, context: context)
                result?.addInfo(info: f)
            }
        }
        return result
    }
    public func setMediaInfo (mediaKey: String, contentLength: Int64, mimeType: String?){
        
        guard let media = self.findMedia(mediaKey: mediaKey, autoCreate: true) else {
            return
        }
        
//        writeQueue.sync (flags: .barrier) {
            if contentLength > 0{
                media.contentLength = contentLength
            }
            if let mt = mimeType{
                media.mimeType = mt
            }
            do{
                try context.save()
                print ("key \(mediaKey) set media info \(contentLength) \(mimeType!) - id \(media.objectID)")
            }
            catch {
                print ("key \(mediaKey) set media info \(contentLength) \(mimeType!) - error \(error)")
            }
//        }
    }
    private init(){
        //        self.context = context
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        //        let mediaManagerBundle = Bundle(identifier: "com.artsncode.ACMediaManager")
        //
        //        let modelURL = mediaManagerBundle!.url(forResource: "MediaManagerDataModel", withExtension: "momd", subdirectory: "Engine")!
        
        //        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        //        let container = NSPersistentContainer(name: "MyFramework", managedObjectModel: managedObjectModel)
        
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: "MediaManagerDataModel", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }
        
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
        let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let fileURL = URL(string: "MediaManagerDataModel.sql", relativeTo: dirURL)
        do {
            try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                   configurationName: nil,
                                                                   at: fileURL, options: nil)
        } catch {
            fatalError("Error configuring persistent store: \(error)")
        }
        
        
        self.mediaManagerManagedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        
        //        let dbFile = (fileManager.documentsDirectory()?.appendingPathComponent("VLMediaCacheManagerDB"))!
        //        store = try! Store(directoryPath: dbFile.path, maxDbSizeInKByte: 100_000)
        cacheDirectory = (fileManager.documentsDirectory()?.appendingPathComponent("VLMediaCacheManager"))!
        
        self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        //        self.task = Plan.every(10.minutes).do(queue: dispatchQueue, action:{
        //            self.checkLimit()
        //        }
        //        )
    }
    private func delete (media: Media) {
        let url = self.cacheDirectory.appendingPathComponent(media.key, isDirectory: true)
        if fileManager.removeDirectory(url){
            print ("Directory \(url.description) deleted")
            
            context.delete(media)
            try? context.save()
        }
    }
    public func checkLimit () {
        do{
            var size = try fileManager.allocatedSizeOfDirectory(at: cacheDirectory)
            print ("Cache DB Size = \(size.formattedWithSeparator)")
            if (size > MediaCacheDBStorage.MAX_CACHE_SIZE) {
                var date = Date()
                date.add(.minute, value: -10)
                
                if let expiredMedias = Media.fetchMultiple(beforeDate: date, context: context) {
                    for media in expiredMedias
                    {
                        //                        let url = self.cacheDirectory.appendingPathComponent(media.key, isDirectory: true)
                        //                        size = try fileManager.allocatedSizeOfDirectory(at: url)
                        //                        totalSize = totalSize + size
                        //                        print ("size of \(media.key) directory is \(size.formattedWithSeparator)")
                        print ("deleting \(media.key) -- \(String(describing: media.createdOn)) - resulting size \(size)")
                        self.delete(media: media)
                        size = try fileManager.allocatedSizeOfDirectory(at: cacheDirectory)
                        print ("deleted \(media.key) -- \(String(describing: media.createdOn)) - resulting size \(size)")
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
        if let expiredMedias = Media.fetchMultiple(beforeDate: before, context: context) {
            expiredMedias.forEach{ media in
                print ("Deleting media \(media.key)")
                self.delete(media: media)
            }
            
        }
    }
    
    //    public func test(){
    //        let mediaBox = store.box(for: MediaDA.self)
    //        let fragmentBox = store.box(for: MediaFragmentDA.self)
    //        let media = MediaDA(key: "12345")
    //        do{
    //            let id = try mediaBox.put(media)
    //            print ("put \(media) id is \(id)")
    //        }
    //        catch{
    //
    //        }
    //
    //
    //        try? mediaBox.all().forEach{media in
    //            print (media.key)
    //            media.fragments.forEach{
    //                print ($0.key)
    //            }
    //
    //        }
    //
    //        let query: Query<MediaDA>? = try? mediaBox.query {
    //            MediaDA.key == "12345"
    //        }.build()
    //        if let media = try? query?.find().first {
    //            let fragment = MediaFragmentDA(key: "xxxxx", offset: 0, length: 10)
    //            fragment.media.target = media
    //            try? fragmentBox.put(fragment)
    //        }
    //
    //    }
    
}
