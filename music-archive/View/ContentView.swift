import SwiftUI
import CoreData
import AppKit

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var metadataSearch = MetadataSearch()
    @StateObject private var eventLogger = EventLogger()
    @StateObject private var playlistStore = PlaylistStore()

    // Random playback state
    @State private var isRandomPlaying = false
    @State private var randomHistory: [URL] = []
    @State private var currentRandomIndex: Int = -1

    var body: some View {
        HStack {
            // Left Column: Archive File List
            VStack {
                ArchiveFileListView(
                    metadataSearch: metadataSearch,
                    audioManager: audioManager,
                    eventLogger: eventLogger,
                    playlistStore: playlistStore
                )
                HStack {
                    Button("Refresh Archive") {
                        metadataSearch.startSearch()
                        eventLogger.log("Refreshed archive", isError: false)
                    }
                    .padding()
                    Spacer()
                }
            }
            .padding()
            
            // Center Column: Playlist View and controls
            VStack {
                HStack {
                    Button("New Playlist") {
                        // Create a new playlist using all archive files (in random order).
                        playlistStore.createNewPlaylist(withTracks: metadataSearch.audioFiles, name: "My Playlist")
                        eventLogger.log("Created new playlist", isError: false)
                    }
                    Button("Load Playlist") {
                        // For demonstration, simply load the first saved playlist.
                        if let first = playlistStore.playlists.first {
                            playlistStore.loadPlaylist(first)
                            eventLogger.log("Loaded playlist \(first.name)", isError: false)
                        }
                    }
                }
                .padding()
                PlaylistView(playlistStore: playlistStore, audioManager: audioManager, eventLogger: eventLogger)
            }
            .padding()
            
            // Right Column: Control Panel, Now Playing, and Event Log
            VStack {
                // --- Control Panel ---
                VStack {
                    PlayButton(
                        metadataSearch: metadataSearch,
                        audioManager: audioManager,
                        eventLogger: eventLogger,
                        startPlaybackAction: startRandomPlayback
                    )
                    HStack {
                        Button(action: { previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        .padding()
                        Button(action: { nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        .padding()
                    }
                }
                
                // --- Now Playing Section ---
                if let currentFile = audioManager.currentFile {
                    VStack(alignment: .leading) {
                        Text("Now Playing:")
                            .font(.headline)
                        HStack {
                            Text(currentFile.lastPathComponent)
                                .lineLimit(1)
                            Spacer()
                            StarRatingView(file: currentFile)
                        }
                        .padding(.vertical, 4)
                        if let creationDate = try? currentFile.resourceValues(forKeys: [.creationDateKey]).creationDate {
                            Text(DateFormatter.dateOnly.string(from: creationDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .contextMenu {
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([currentFile])
                        }
                    }
                }
                
                Divider()
                
                // --- Event Log ---
                VStack(alignment: .leading) {
                    Text("Archive History")
                        .font(.headline)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(eventLogger.events) { event in
                                VStack(alignment: .leading, spacing: 2) {
                                    if event.firstOfDay {
                                        Text(DateFormatter.dateOnly.string(from: event.date))
                                            .bold()
                                    }
                                    Text("\(DateFormatter.timeOnly.string(from: event.date)): \(event.message)")
                                        .foregroundColor(event.isError ? .red : .primary)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(width: 300, height: 400)
                }
            }
            .padding()
        }
        .onAppear {
            metadataSearch.startSearch()
            // Connect log callback.
            audioManager.logEvent = { message, isError in
                eventLogger.log(message, isError: isError)
            }
            // Handle error and finish callbacks for random playback.
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
