//
//  MediaFragment+CoreDataClass.swift
//  ACMediaManager
//
//  Created by Hussein AlMawla on 7/15/20.
//  Copyright © 2020 Arts'n'Code. All rights reserved.
//
//

import Foundation
import CoreData


public class MediaFragment: NSManagedObject {
    var mediaKey: String?
    
    lazy var range: ByteRange = {
        return ByteRange.fromOffsetAndLength(offset: self.offset, length: self.length)
    }()
    
    public init (mediaKey: String, offset: Int64, length: Int64, key: String, context: NSManagedObjectContext){
        
        let mediaFragmentEntityDescription = NSEntityDescription.entity(forEntityName: "Media", in: context)!
        super.init(entity: mediaFragmentEntityDescription, insertInto: context)
        
        self.offset = offset
        self.length = length
        self.key = key
        self.mediaKey = mediaKey
    }
    public init (mediaKey: String, offset: Int64, length: Int64, context: NSManagedObjectContext){
        
        let mediaFragmentEntityDescription = NSEntityDescription.entity(forEntityName: "Media", in: context)!
        super.init(entity: mediaFragmentEntityDescription, insertInto: context)
        
        self.offset = offset
        self.length = length
        self.key = UUID().uuidString
        self.mediaKey = mediaKey
    }
    
    func debugDescription()->String {
        return "mediaKey \(String(describing: mediaKey)) - key: \(key) - offset:\(offset) - length:\(length) - range: \(range)"
    }
    
    func toAbsoluteRange (relativeRange: ByteRange) -> Range<Int> {
        let newRange = (relativeRange.lowerBound - offset)..<(relativeRange.upperBound - offset)
        return newRange.subdataRange
    }
}
