//
//  ArchiveMetadata.swift
//  music-archive
//
//  Created by Ben Kamen on 2/2/25.
//

import Foundation

class ArchiveMetadata {
    // Save a rating (1–5) as an extended attribute.
    static func setRating(for file: URL, rating: Int) throws {
        let key = "user.rating"
        guard (1...5).contains(rating),
              let data = "\(rating)".data(using: .utf8) else { return }
        let result = data.withUnsafeBytes { bytes in
            setxattr(file.path, key, bytes.baseAddress, data.count, 0, 0)
        }
        if result != 0 {
            throw NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(errno),
                userInfo: nil
            )
        }
    }
    
    // Retrieve the stored rating.
    static func getRating(for file: URL) -> Int? {
        let key = "user.rating"
        let size = getxattr(file.path, key, nil, 0, 0, 0)
        guard size > 0 else { return nil }
        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes { bytes in
            getxattr(file.path, key, bytes.baseAddress, size, 0, 0)
        }
        guard result != -1,
              let ratingStr = String(data: data, encoding: .utf8),
              let rating = Int(ratingStr) else { return nil }
        return rating
    }
    

}

