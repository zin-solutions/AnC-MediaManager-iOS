//
//  MediaCacheDBStorage.swift
//  CachingVideoTest
//
//  Created by Hassan Moghnie on 1/5/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation
import CoreData


class MediaCacheDBStorage {
    static let MAX_CACHE_SIZE = 500 * 1024 * 1024
    
    //    let store: Store
    private let fileManager = FileManager.init()
    let cacheDirectory: URL
    
    public static var shared:MediaCacheDBStorage?
    public static func initDBStorage(){
        shared = MediaCacheDBStorage()
    }
    
    let persistentStoreCoordinator:NSPersistentStoreCoordinator
    let mediaManagerManagedObjectModel:NSManagedObjectModel
    let context:NSManagedObjectContext
    
    
    public func findMedia (mediaKey: String, autoCreate: Bool = false) -> Media?{
        print("Fetch media \(mediaKey)")
        var media = Media.fetch(findByKey: mediaKey, context: context)
        if media != nil{
            print("Found media \(mediaKey)")
            return media
        }
        print("Did not find media \(mediaKey)")
        
        if !autoCreate{
            return nil
        }
        
        print("Creating media \(mediaKey)")
        media = Media(key: mediaKey, context: context)
        try? context.save()
        
        return media
    }
    
    public func addFragment (mediaKey: String, offset: Int64, data: Data){
        print("Adding fragment to media \(mediaKey)")
        
        guard let media = findMedia(mediaKey: mediaKey, autoCreate: true) else{
            print("Error - Couldn't find media")
            return
        }
        print("addFragment -- writeQueue")
        //            let fragmentBox = self.store.box(for: MediaFragmentDA.self)
        let key = UUID().uuidString
        let fragment = MediaFragment(mediaKey: key, offset: offset, length: Int64(data.count), context: context)
        
        do{
            print("Saving fragment for media \(mediaKey)")
            fragment.media = media
            try context.save()
        }
        catch{
            print("Error - Saving fragment for media \(mediaKey)")
            return
        }
        do{
            print("Storing fragment in file for media \(mediaKey)")
            let url = self.cacheDirectory.appendingPathComponent(mediaKey, isDirectory: true).appendingPathComponent(fragment.key)
            _ = self.fileManager.createSubdirectory(mediaKey, atUrl: self.cacheDirectory)
            try data.write(to: url)
        }
        catch{
            print("Error - Storing fragment in file for media \(mediaKey)")
            context.delete(fragment)
            try? context.save()
        }
    }
    public func data (fragment: MediaFragment) -> Data?{
        let url = self.cacheDirectory.appendingPathComponent(fragment.mediaKey!, isDirectory: true).appendingPathComponent(fragment.key)
        return try? Data(contentsOf: url)
    }
    
    public func findMediaDto(key: String, autoCreate: Bool = false) -> Media? {
        print("Fetching media DTO for \(key) - AutoCreate \(autoCreate)")
        if let media = self.findMedia(mediaKey: key, autoCreate: autoCreate) {
            print("Getting media fragments for media \(media.key)")
            let mediaFragments: [MediaFragment] = (media.mediaFragments?.toArray())!
            print("Found \(mediaFragments.count) media fragments")
            print("Filling \(mediaFragments.count) media fragments to media's info")
            mediaFragments.forEach{fragment in
                media.addInfo(info: fragment)
            }
            return media
        }
        return nil
    }
    
    public func setMediaInfo (mediaKey: String, contentLength: Int64, mimeType: String?){
        
        guard let media = self.findMedia(mediaKey: mediaKey, autoCreate: true) else {
            print("No need to set media info")
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
        
        cacheDirectory = (fileManager.documentsDirectory()?.appendingPathComponent("ACMediaCacheManager"))!
        
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
    }
    private func delete (media: Media) {
        let url = self.cacheDirectory.appendingPathComponent(media.key, isDirectory: true)
        if fileManager.removeDirectory(url){
            print ("Directory \(url.description) deleted")
        }
        context.delete(media)
        try? context.save()
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
                        print ("deleting \(media.key) -- \(String(describing: media.createdOn)) - resulting size \(size)")
                        self.delete(media: media)
                        size = try fileManager.allocatedSizeOfDirectory(at: cacheDirectory)
                        print ("deleted \(media.key) -- \(String(describing: media.createdOn)) - resulting size \(size)")
                        if (size < MediaCacheDBStorage.MAX_CACHE_SIZE){
                            break
                        }
                    }
                    
                }
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
    
    public func clearCache (){
        if let allMedias = Media.fetchAll(context: context) {
            if allMedias.count == 0 {
                print("Nothing to clear")
                return
            }
            allMedias.forEach{ media in
                print ("Deleting media \(media.key)")
                self.delete(media: media)
            }
            
        }
    }
    
}
