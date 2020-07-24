//
//  Blob.swift
//  WaynyoIOS
//
//  Created by Hassan Moghnie on 12/14/18.
//  Copyright © 2018 Hassan Moghnie. All rights reserved.
//

import Foundation

public class Blob: Decodable{
    public var id: String
    public var contentType: String
    public var url: URL
    public var thumbnail: Blob?
    
    /// Might be removed
    public var height: Float?
    public var width: Float?
    /// -------------
    
    
    public init(id:String, contentType:String, url:URL) {
        self.id = id
        self.contentType = contentType
        self.url = url
    }
    
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
        return contentType.starts(with: "video")
    }
    public func getVideoBlob()-> Blob? {
        if (isVideo()){
            return self
        }
        return nil
    }
    
    public func getImageBlob()-> Blob?{
        if (isVideo()){
            return self.thumbnail
        }
        else{
            return self
        }
    }
}
