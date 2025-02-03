//
//  PlayButton.swift
//  music-archive
//
//  Created by Ben Kamen on 2/3/25.
//

import SwiftUI

struct PlayButton: View {
    
    @ObservedObject var metadataSearch: MetadataSearch
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var eventLogger: EventLogger
    
    var startPlaybackAction: () -> Void
    
    var body: some View {
        Button(action: {
            if let current = audioManager.currentFile {
                   if audioManager.isPlaying {
                       audioManager.pauseAudio()
                   } else if audioManager.isPaused {
                       do {
                           try audioManager.playAudio(from: current)
                       } catch {
                           eventLogger.log("Failed to resume \(current.lastPathComponent): \(error.localizedDescription)", isError: true)
                       }
                   }
               } else {
                   // Optionally start random playback
                   startPlaybackAction()
               }
        }) {
            let imageName: String = audioManager.currentFile != nil && audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill"
            Image(systemName: imageName)
                .resizable()
                .frame(width: 80, height: 80)
                .padding()
        }
    }
}
