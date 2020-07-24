//
//  PreheatingManager.swift
//  WaynYo
//
//  Created by Hassan Moghnie on 3/10/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation

public class PreheatingManager {
    
    public static let shared = PreheatingManager()
//    private let dispatchQueue = DispatchQueue.init(label: "preheating_queue", qos: .background, attributes: .concurrent)
    
    private init (){
        
    }
    
    public func preheat (blobs: [Blob]) {
        
//        if Session.shared.autoPlay{
            for blob in blobs {
                let url = blob.url
                print ("PreheatingManager --- request for \(blob.id)")
                MediaCacheManager.shared.preheat(url: url, key: blob.id)
            }
//        }
    }
}
