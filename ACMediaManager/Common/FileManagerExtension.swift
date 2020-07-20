//
//  FileManagerExtension.swift
//  WaynYo
//
//  Created by Hassan Moghnie on 3/5/20.
//  Copyright © 2020 Hassan Moghnie. All rights reserved.
//

import Foundation



extension FileManager {
    
    func cachesDirectory() -> URL? {
        let directories = urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        return directories.first
    }
    
    func documentsDirectory() -> URL? {
        let directories = urls(
            for: .documentDirectory,
            in: .userDomainMask
        )
        return directories.first
    }

    func applicationSupportDirectory () -> URL? {
        let directories = urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        return directories.first
    }
    func createDirectoryAt(_ url: URL) -> Bool {
        do {
            try createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        catch {
            return false
        }
        return true
    }
    
    func createSubdirectory(_ name: String, atUrl url: URL) -> Bool {
        let subdirectoryUrl = url.appendingPathComponent(name, isDirectory: true)
        return self.createDirectoryAt(subdirectoryUrl)
    }
    
    func removeDirectory(_ directory: URL) -> Bool {
        do {
            try removeItem(at: directory)
        }
        catch {
            return false
        }
        return true
    }
    
    func removeFile(at url: URL) -> Bool {
        do {
            try removeItem(at: url)
        }
        catch {
            return false
        }
        return true
    }
    func createFile (fileName: String, inDirectory: URL) -> URL {
        let file = inDirectory.appendingPathComponent(fileName, isDirectory: false)
        return file.absoluteURL
    }
}

public extension FileManager {

    /// Calculate the allocated size of a directory and all its contents on the volume.
    ///
    /// As there's no simple way to get this information from the file system the method
    /// has to crawl the entire hierarchy, accumulating the overall sum on the way.
    /// The resulting value is roughly equivalent with the amount of bytes
    /// that would become available on the volume if the directory would be deleted.
    ///
    /// - note: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
    /// directories, hard links, ...).
    func allocatedSizeOfDirectory(at directoryURL: URL) throws -> UInt64 {

        // The error handler simply stores the error and stops traversal
        var enumeratorError: Error? = nil
        func errorHandler(_: URL, error: Error) -> Bool {
            enumeratorError = error
            return false
        }

        // We have to enumerate all directory contents, including subdirectories.
        let enumerator = self.enumerator(at: directoryURL,
                                         includingPropertiesForKeys: Array(allocatedSizeResourceKeys),
                                         options: [],
                                         errorHandler: errorHandler)!

        // We'll sum up content size here:
        var accumulatedSize: UInt64 = 0

        // Perform the traversal.
        for item in enumerator {

            // Bail out on errors from the errorHandler.
            if enumeratorError != nil { break }

            // Add up individual file sizes.
            let contentItemURL = item as! URL
            accumulatedSize += try contentItemURL.regularFileAllocatedSize()
        }

        // Rethrow errors from errorHandler.
        if let error = enumeratorError { throw error }

        return accumulatedSize
    }
}


fileprivate let allocatedSizeResourceKeys: Set<URLResourceKey> = [
    .isRegularFileKey,
    .fileAllocatedSizeKey,
    .totalFileAllocatedSizeKey,
]


extension URL {

    func regularFileAllocatedSize() throws -> UInt64 {
        let resourceValues = try self.resourceValues(forKeys: allocatedSizeResourceKeys)

        // We only look at regular files.
        guard resourceValues.isRegularFile ?? false else {
            return 0
        }

        // To get the file's size we first try the most comprehensive value in terms of what
        // the file may use on disk. This includes metadata, compression (on file system
        // level) and block size.
        // In case totalFileAllocatedSize is unavailable we use the fallback value (excluding
        // meta data and compression) This value should always be available.
        return UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
    }
}
