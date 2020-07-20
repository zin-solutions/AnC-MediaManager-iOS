//
//  CacheManagerExtensions.swift
//  WaynYo
//
//  Created by Hassan Moghnie on 3/9/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation

extension Dictionary where Value: MediaLoader {
    func findByMediaKey(key: String) -> [MediaLoader]? {
        return Array(self.filter{$0.value.key == key}.values)
    }
    func findByMediaKeyAndType(key: String, type: LoaderType) -> [MediaLoader]? {
        return Array(self.filter{$0.value.key == key && $0.value.type == type}.values)
    }
    func findByType (type: LoaderType) -> [MediaLoader]? {
        return Array(self.filter{$0.value.type == type}.values)
    }
    
}
