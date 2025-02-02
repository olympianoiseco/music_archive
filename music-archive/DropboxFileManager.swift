//
//  DropboxFileManager.swift
//  music-archive
//
//  Created by Ben Kamen on 2/1/25.
//

import Foundation
import SwiftyDropbox

class DropboxFileManager {
    
    private var client: DropboxClient? {
        DropboxClientsManager.authorizedClient
    }
    
    func isFileDownloaded(at localURL: URL) -> Bool {
        guard let fileHandle = try? FileHandle(forReadingFrom: localURL) else { return false }
        defer { try? fileHandle.close() }
        let data = fileHandle.readData(ofLength: 1)
        return !data.isEmpty
    }
    
    // Check if the file exists on Dropbox (by attempting to get its metadata)
    func isFileOnDropbox(at dropboxPath: String, completion: @escaping (Bool) -> Void) {
        client?.files.getMetadata(path: dropboxPath).response { response, _ in
            completion(response != nil)
        }
    }
    
    // Download the file from Dropbox and cache it locally
    func downloadFile(from dropboxPath: String, to localURL: URL, completion: @escaping (Data?) -> Void) {
        client?.files.download(path: dropboxPath).response { response, _ in
            if let (_, fileData) = response {
                try? fileData.write(to: localURL)
                completion(fileData)
            } else {
                completion(nil)
            }
        }
    }
    
    // Retrieve file data: if downloaded locally, load it from disk; otherwise download from Dropbox
    func fileData(for dropboxPath: String, localURL: URL, completion: @escaping (Data?) -> Void) {
        if isFileDownloaded(at: localURL) {
            completion(try? Data(contentsOf: localURL))
        } else {
            downloadFile(from: dropboxPath, to: localURL, completion: completion)
        }
    }
}
