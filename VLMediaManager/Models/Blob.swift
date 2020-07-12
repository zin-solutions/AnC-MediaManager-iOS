//
//  Blob.swift
//  WaynyoIOS
//
//  Created by Hassan Moghnie on 12/14/18.
//  Copyright © 2018 Hassan Moghnie. All rights reserved.
//

import Foundation

class Blob: Decodable{
    var id: String?
    var contentType: String?
    var height: Float?
    var width: Float?
    var subBlobs: [Blob]?
    
    init() {}
    
    func isPortrait () -> Bool {
        guard  let width = self.width, let height = self.height else {
            return false
        }
        return height > width
    }
}

extension Blob: Equatable {
    static public func ==(rhs: Blob, lhs: Blob) -> Bool {
        return rhs.id == lhs.id
    }
}

extension Blob {
    public func isVideo () ->Bool {
        return contentType?.starts(with: "video") ?? false
    }
    public func getVideoBlob()-> Blob? {
        if (isVideo()){
            return self
        }
        return nil
    }
    
    public func getImageBlob()-> Blob?{
        if (isVideo()){
            return subBlobs?.first(where: { (blob) -> Bool in
                (blob.contentType?.starts(with: "image") ?? false)
            })
        }
        else{
            return self
        }
    }
    public func getVideoUrl()-> URL? {
        let blobId = self.getVideoBlob()?.id
        
        guard
            blobId != nil,
            let urlString = BlobUtils.blobUrl(blobId: blobId),
            let url = URL(string: urlString)
            else { return nil}
        
        return url
    }
    public func getImageUrl()-> URL?{
        let blob = self.getImageBlob()
        
        guard let blobId = blob?.id,
            let urlString = BlobUtils.blobUrl(blobId: blobId),
            let url = URL(string: urlString)
            else { return nil}
        return url
    }
}
