import SwiftUI
import CoreData
import AppKit

struct ContentView: View {
    
    @StateObject private var audioManager = AudioManager()
    @StateObject private var metadataSearch = MetadataSearch()
    @StateObject private var eventLogger = EventLogger()
    @StateObject private var playlistStore = PlaylistStore()
    
    // Random playback state (if desired).
    @State private var isRandomPlaying = false
    @State private var randomHistory: [URL] = []
    @State private var currentRandomIndex: Int = -1

    var body: some View {
        Group {
            if metadataSearch.audioFiles.isEmpty {
                
                OnboardingView()
                
            } else {
                
                HStack {
                    // Left: List of Playlists
                    PlaylistListView(playlistStore: playlistStore,
                                     eventLogger: eventLogger,
                                     metadataSearch: metadataSearch,
                                     currentPlaylist: $playlistStore.currentPlaylist)
                    
                    // Middle: Current Playlist
                    CurrentPlaylistView(playlistStore: playlistStore,
                                        audioManager: audioManager,
                                        eventLogger: eventLogger)
                    
                    // Right: Transport Controls, Now Playing, and Event Log
                    TransportView(metadataSearch: metadataSearch,
                                  audioManager: audioManager,
                                  eventLogger: eventLogger,
                                  startRandomPlayback: startRandomPlayback,
                                  nextTrack: nextTrack,
                                  previousTrack: previousTrack)
                }
            
        }
    }.onAppear {
        metadataSearch.startSearch()
        
        audioManager.logEvent = { message, isError in
            eventLogger.log(message, isError: isError)
        }
        audioManager.errorHandler = { failedFile in
            if isRandomPlaying {
                eventLogger.log("Error with \(failedFile.lastPathComponent), skipping...", isError: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { nextTrack() }
            }
        }
        audioManager.finishHandler = {
            if isRandomPlaying {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { nextTrack() }
            }
        }
    }
    .padding()
    .onReceive(playlistStore.$currentPlaylist) { playlist in
        if let playlist = playlist {
            print("Current playlist updated: \(playlist.name) with \(playlist.tracks.count) tracks")
        } else {
            print("Current playlist is nil")
        }
    }
}
    
    // MARK: - Random Playback Controls
    
    func startRandomPlayback() {
        guard !metadataSearch.audioFiles.isEmpty else {
            eventLogger.log("No files available for random playback", isError: true)
            return
        }
        randomHistory = []
        currentRandomIndex = -1
        isRandomPlaying = true
        eventLogger.log("Started random playback", isError: false)
        nextTrack()
    }
    
    func nextTrack() {
        guard !metadataSearch.audioFiles.isEmpty else {
            eventLogger.log("No files available for random playback", isError: true)
            return
        }
        var nextFile: URL?
        if currentRandomIndex < randomHistory.count - 1 {
            currentRandomIndex += 1
            nextFile = randomHistory[currentRandomIndex]
        } else {
            let candidates = metadataSearch.audioFiles.filter { $0 != audioManager.currentFile }
            nextFile = candidates.randomElement() ?? metadataSearch.audioFiles.randomElement()
            if let file = nextFile {
                randomHistory.append(file)
                currentRandomIndex = randomHistory.count - 1
            }
        }
        if let file = nextFile {
            do {
                try audioManager.playAudio(from: file)
            } catch {
                eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
            }
        }
    }
    
    func previousTrack() {
        if audioManager.currentPlaybackTime > 5.0 {
            audioManager.restartCurrentTrack()
            return
        }
        guard currentRandomIndex > 0 else { return }
        currentRandomIndex -= 1
        let file = randomHistory[currentRandomIndex]
        do {
            try audioManager.playAudio(from: file)
        } catch {
            eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
        }
    }
}
