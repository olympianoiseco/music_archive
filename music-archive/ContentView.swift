import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var metadataSearch = MetadataSearch()
    @StateObject private var eventLogger = EventLogger()

    var body: some View {
        HStack {
            VStack {
                List(metadataSearch.audioFiles, id: \.self) { file in
                    HStack {
                        Text(file.lastPathComponent)
                        Spacer()
                        Button {
                            if audioManager.isPlaying && audioManager.currentFile == file {
                                audioManager.stopAudio()
                            } else {
                                do {
                                    try audioManager.playAudio(from: file)
                                } catch {
                                    eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
                                    print("failed to play audio \(error.localizedDescription)")
                                }
                            }
                        } label: {
                            Image(systemName: (audioManager.isPlaying && audioManager.currentFile == file)
                                  ? "stop.circle"
                                  : "play.circle")
                        }
                    }
                }
                
                HStack {
                    Button("Refresh Archive") {
                        metadataSearch.startSearch()
                        eventLogger.log("Refreshed archive")
                    }
                    .padding()
                    Spacer()
                }
            }
            .padding()
            
            // Right-hand sidebar: Event History
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
                .frame(width: 300)
            }
            .padding()
        }
        .onAppear {
            metadataSearch.startSearch()
            // Connect AudioManager to the logger.
            audioManager.logEvent = { message, isError in
                eventLogger.log(message, isError: isError)
            }
        }
        .padding()
    }
}


// Debug preview
#Preview {
    ContentView()
}
