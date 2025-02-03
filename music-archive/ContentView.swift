import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var metadataSearch = MetadataSearch()
    @StateObject private var eventLogger = EventLogger()

    // Random playback state
    @State private var isRandomPlaying = false
    @State private var randomHistory: [URL] = []
    @State private var currentRandomIndex: Int = -1
    
    var body: some View {
        HStack {
            // Left: File List
            VStack {
                List(metadataSearch.audioFiles, id: \.self) { file in
                    HStack {
                        Text(file.lastPathComponent)
                        Spacer()
                        // Display the star rating control inline.
                        StarRatingView(file: file)
                        Button {
                            // Manual selection cancels random mode.
                            isRandomPlaying = false
                            do {
                                try audioManager.playAudio(from: file)
                            } catch {
                                eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
                            }
                        } label: {
                            Image(systemName: (audioManager.isPlaying && audioManager.currentFile == file)
                                  ? "stop.circle"
                                  : "play.circle")
                        }
                    }
                    .contextMenu {
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([file])
                        }
                    }
                }
                
                
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
            
            // Right: Control Panel & Log
            VStack {
                // --- Control Panel ---
                VStack {
                    // Large Random Play/Stop Button
                    Button(action: {
                        if isRandomPlaying {
                            isRandomPlaying = false
                            audioManager.stopAudio()
                            eventLogger.log("Stopped random playback", isError: false)
                        } else {
                            startRandomPlayback()
                        }
                    }) {
                        Image(systemName: isRandomPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(isRandomPlaying ? .red : .green)
                            .padding()
                    }
                    
                    // Fast-forward, Rewind, Restart Buttons
                    HStack {
                        Button(action: { previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        .padding()
                        
                        Button(action: { restartCurrentTrack() }) {
                            Image(systemName: "gobackward")
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
                    .frame(width: 300, height: 400) // adjust as needed
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
            // If an error occurs or a track finishes while in random mode, jump to the next track.
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
            // Use the next file from history.
            currentRandomIndex += 1
            nextFile = randomHistory[currentRandomIndex]
        } else {
            // Pick a new random file (avoid repeating current file if possible).
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
        guard currentRandomIndex > 0 else { return }
        currentRandomIndex -= 1
        let file = randomHistory[currentRandomIndex]
        do {
            try audioManager.playAudio(from: file)
        } catch {
            eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
        }
    }
    
    func restartCurrentTrack() {
        audioManager.restartCurrentTrack()
    }
}



// Debug preview
#Preview {
    ContentView()
}
