//
//  MediaFragment+CoreDataProperties.swift
//  ACMediaManager
//
//  Created by Hussein AlMawla on 7/15/20.
//  Copyright © 2020 Arts'n'Code. All rights reserved.
//
//

import Foundation
import CoreData


extension MediaFragment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaFragment> {
        return NSFetchRequest<MediaFragment>(entityName: "MediaFragment")
    }

    @NSManaged public var key: String
    @NSManaged public var offset: Int64
    @NSManaged public var length: Int64
    @NSManaged public var media: Media?

}
