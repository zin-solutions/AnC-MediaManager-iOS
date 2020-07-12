//
//  ReaderWriterClock.swift
//  WaynYo
//
//  Created by Hassan Moghnie on 3/12/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation

public class ReaderWriterLock {
    private let queue: DispatchQueue

    init (name: String){
         queue = DispatchQueue(label: name, attributes: .concurrent)
    }
    public func concurrentlyRead<T>(_ block: (() throws -> T)) rethrows -> T {
        return try queue.sync {
            try block()
        }
    }

    public func exclusivelyWrite(_ block: @escaping (() -> Void)) {
        queue.async(flags: .barrier) {
            block()
        }
    }
}

