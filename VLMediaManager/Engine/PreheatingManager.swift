//
//  PreheatingManager.swift
//  WaynYo
//
//  Created by Hassan Moghnie on 3/10/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation
import Nuke

class PreheatingManager {
    
    public static let shared = PreheatingManager()
    let preheater = ImagePreheater()
    private let dispatchQueue = DispatchQueue.init(label: "preheating_queue", qos: .background, attributes: .concurrent)
    
    private init (){
        
    }
    public func preheatImage (urls: [URL]){
        dispatchQueue.async {
            self.preheater.startPreheating(with: urls)
        }
    }
    public func preheat (blobs: [Blob]) {
        
//        if Session.shared.autoPlay{
            for blob in blobs {
                if let url = blob.getVideoUrl(){
                    dispatchQueue.async {
                        print ("PreheatingManager --- request for \(blob.id!)")
                        MediaCacheManager.shared.preheat(url: url, key: blob.id!)
                    }
                }
            }
//        }
    }
}
