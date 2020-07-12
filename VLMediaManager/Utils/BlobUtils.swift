//
//  BlobUtils.swift
//  VLMediaManager
//
//  Created by Hussein AlMawla on 7/12/20.
//  Copyright © 2020 Hussein AlMawla. All rights reserved.
//

import Foundation

class BlobUtils{
    public static func blobUrl(blobId: String?)->String?{
        if let blobId = blobId {
            return "\(baseUrl)blob/download/\(blobId)"
        }
        return nil
    }
}
