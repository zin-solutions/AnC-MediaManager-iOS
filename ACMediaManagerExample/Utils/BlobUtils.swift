//
//  BlobUtils.swift
//  VLMediaManager
//
//  Created by Hussein AlMawla on 7/12/20.
//  Copyright © 2020 Hussein AlMawla. All rights reserved.
//

import Foundation
import ACMediaManager

class BlobUtils{
    public static func blobUrl(blobId: String?)->String?{
        if let blobId = blobId {
            return "\(baseUrl)blob/download/\(blobId)"
        }
        return nil
    }
    
    public static func getVideoUrl(blob: Blob)-> URL? {
        let blobId = blob.getVideoBlob()?.id
        
        guard
            blobId != nil,
            let urlString = BlobUtils.blobUrl(blobId: blobId),
            let url = URL(string: urlString)
            else { return nil}
        return url
    }
}
