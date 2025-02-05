//
//  FileInfo.swift
//  music-archive
//
//  Created by Ben Kamen on 2/5/25.
//

import SwiftUI

struct FileInfo: View {
    
    let file: URL
    @ObservedObject var audioManager: AudioManager

    var body: some View {
        HStack {
            Text(file.lastPathComponent)
            Spacer()
            StarRatingView(file: file)
        }
        .background(audioManager.currentFile == file ? Color.blue.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
        
    }
}
