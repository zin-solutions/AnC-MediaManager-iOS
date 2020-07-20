//
//  Media+CoreDataProperties.swift
//  ACMediaManager
//
//  Created by Hussein AlMawla on 7/15/20.
//  Copyright © 2020 Arts'n'Code. All rights reserved.
//
//

import Foundation
import CoreData


extension Media {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Media> {
        return NSFetchRequest<Media>(entityName: "Media")
    }

    @NSManaged public var key: String
    @NSManaged public var createdOn: Date?
    @NSManaged public var mimeType: String?
    @NSManaged public var contentLength: Int64
    @NSManaged public var mediaFragments: NSSet?

}

// MARK: Generated accessors for mediaFragments
extension Media {

    @objc(addMediaFragmentsObject:)
    @NSManaged public func addToMediaFragments(_ value: MediaFragment)

    @objc(removeMediaFragmentsObject:)
    @NSManaged public func removeFromMediaFragments(_ value: MediaFragment)

    @objc(addMediaFragments:)
    @NSManaged public func addToMediaFragments(_ values: NSSet)

    @objc(removeMediaFragments:)
    @NSManaged public func removeFromMediaFragments(_ values: NSSet)

}
