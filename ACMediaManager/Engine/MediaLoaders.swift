//
//  MediaLoaderDictionary.swift
//  WaynYo
//
//  Created by Hassan Moghnie on 3/12/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation

class MediaLoaders: NSObject{
    
    let lock = ReaderWriterLock (name: "MediaLoaderDictionary")
    let rwLock = NSLock()
    var loaderDictionary = [URLSessionTask: MediaLoader]()
    public func add(task: URLSessionTask, mediaLoader: MediaLoader){
 //       rwLock.lock(); defer{ rwLock.unlock()}
         self.lock.exclusivelyWrite {
            self.loaderDictionary[task] = mediaLoader
        }
    }
    public func remove (task: URLSessionTask){
//        rwLock.lock(); defer{ rwLock.unlock()}
        self.lock.exclusivelyWrite {
            self.loaderDictionary.removeValue(forKey: task)
        }
    }
    public func remove (mediaLoader: MediaLoader){
//        rwLock.lock(); defer{ rwLock.unlock()}
        self.lock.exclusivelyWrite {
            if let task = mediaLoader.task{
                self.loaderDictionary.removeValue(forKey: task)
            }
        }
    }
    public func find (task: URLSessionTask) -> MediaLoader? {
//        rwLock.lock(); defer{ rwLock.unlock()}
        self.lock.concurrentlyRead({
            return loaderDictionary[task]
        })
    }
    
    public func findByMediaKey(key: String) -> [MediaLoader]? {
//        rwLock.lock(); defer{ rwLock.unlock()}
        self.lock.concurrentlyRead({
           return Array(self.loaderDictionary.filter {$0.value.key == key}.values)
        })
    }
    public func findByMediaKeyAndType(key: String, type: LoaderType) -> [MediaLoader]? {
//        rwLock.lock(); defer{ rwLock.unlock()}
        self.lock.concurrentlyRead({
            return Array(self.loaderDictionary.filter {$0.value.key == key && $0.value.type == type}.values)
        })
    }
    public func findByType (type: LoaderType) -> [MediaLoader]? {
//        rwLock.lock(); defer{ rwLock.unlock()}
        self.lock.concurrentlyRead({
            return Array(self.loaderDictionary.filter {$0.value.type == type}.values)
       })
    }
    public func printAll() {
        self.lock.concurrentlyRead({
            self.loaderDictionary.forEach({key, value in
                print ("media loader -\(value.key) - \(value.type)")
            })
        })
    }
}
