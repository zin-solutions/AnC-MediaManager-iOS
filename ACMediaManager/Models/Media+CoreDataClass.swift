//
//  Media+CoreDataClass.swift
//  ACMediaManager
//
//  Created by Hussein AlMawla on 7/15/20.
//  Copyright © 2020 Arts'n'Code. All rights reserved.
//
//

import Foundation
import CoreData


public class Media: NSManagedObject {
    var compacted = false
    private(set) var info = [MediaFragment]()
    
    public init (key: String, context: NSManagedObjectContext){
        let mediaEntityDescription = NSEntityDescription.entity(forEntityName: "Media", in: context)!
        super.init(entity: mediaEntityDescription, insertInto: context)
        self.key = key
    }
    
    class func fetch(findByKey key: String, context: NSManagedObjectContext) -> Media? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Media")

        let predicate = NSPredicate(format: "key = %@", key)
        fetchRequest.predicate = predicate

        do {
            let media = try context.fetch(fetchRequest)
            return media.first as? Media
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    class func fetchMultiple(beforeDate date: Date, context: NSManagedObjectContext) -> [Media]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Media")

        let predicate = NSPredicate(format: "createdOn < %@", DateUtils.getCurrentTimeStampWOMiliseconds(dateToConvert: date))
        fetchRequest.predicate = predicate
        
        let sort = NSSortDescriptor(key: "createdOn", ascending: true)
        fetchRequest.sortDescriptors = [sort]

        do {
            let media = try context.fetch(fetchRequest)
            return media as? [Media]
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func addInfo (info: MediaFragment){
        self.info.append(info)
        self.compacted = false
    }
    func getAvailableRange (requested: ByteRange) -> MediaCacheResponse?{
        let ranges = self.info.compactMap{$0.range}
        
        if ranges.count == 0{
            return MediaCacheResponse (availableRange: nil, neededRange: requested)
        }
        let combinedRanges = combine(ranges)
        let availableRanges = combinedRanges.filter{
            $0.relativePosition(of: Int64(requested.lowerBound)) == .inside
        }
        var availableRange: ByteRange? = nil
        var neededRange: ByteRange? = nil
        var nextAvailable: ByteRange? = nil
        if availableRanges.count > 0{
            let r = availableRanges[0]
            availableRange = requested.lowerBound..<min(requested.upperBound, r.upperBound)
            if availableRange?.fullySatisfies(requested) ?? false{
                return MediaCacheResponse (availableRange: availableRange, neededRange: nil)
            }
        }
        if let a = availableRange{
            let index = combinedRanges.firstIndex(of: a)
            if var i = index {
                i = i + 1
                if combinedRanges.count > i{
                    nextAvailable = combinedRanges[i]
                }
            }
            if let na = nextAvailable{
                let minUpperBound = min(na.lowerBound, requested.upperBound)
                if minUpperBound > a.upperBound{
                    neededRange = a.upperBound..<minUpperBound
                }
            }
            else {
                if a.upperBound < requested.upperBound{
                    neededRange = a.upperBound..<requested.upperBound
                }
            }
        }
        else{
            let nextAvailables = combinedRanges.filter {
                $0.relativePosition(of: Int64(requested.lowerBound)) == .before
            }
            if nextAvailables.count > 0 {
                nextAvailable = nextAvailables[0]
            }
            if let na = nextAvailable{
                let minUpperBound = min(requested.upperBound, na.lowerBound)
                if minUpperBound > requested.lowerBound {
                    neededRange = requested.lowerBound..<minUpperBound
                }
            }
            else {
                neededRange = requested
            }
        }
        
        return MediaCacheResponse(availableRange: availableRange, neededRange: neededRange)
    }
    func neededAssembly (range: ByteRange) -> [MediaFragmentAssembly]? {
        
        let neededFragements = info.filter{
            $0.range.intersects(range)
        }.sorted{lhs, rhs in
            lhs.offset < rhs.offset
        }
        let combined = combine(neededFragements.compactMap{
            $0.range
        })
        if combined.count != 1 {
            return nil
        }
        
        var remainingRange: ByteRange = range
        var assemblyInfos = [MediaFragmentAssembly]()
        for dataFragment in neededFragements{
            let leadingIntersection = dataFragment.range.leadingIntersection(in: remainingRange)
            if let intersection = leadingIntersection{
                assemblyInfos.append(MediaFragmentAssembly(mediaFragement: dataFragment, usedRange: intersection))
                remainingRange = intersection.upperBound..<remainingRange.upperBound
                if remainingRange.length == 0{
                    break
                }
            }
        }
        if (remainingRange.length != 0){ // it means we cannot satisfy the data in order
            return nil
        }
        return assemblyInfos
    }
    func data (assembly: MediaFragmentAssembly) -> Data?{
        var data = Data()
        if let d = MediaCacheDBStorage.shared?.data(fragment: assembly.mediaFragment){
            data.append(d.subdata(in: assembly.mediaFragment.toAbsoluteRange(relativeRange: assembly.usedRange)))
        }
        if (data.count == 0){
            return nil
        }
        return data
    }
}
