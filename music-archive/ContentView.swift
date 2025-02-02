import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var metadataSearch = MetadataSearch()

    var body: some View {
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
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            metadataSearch.startSearch()
        }
        .padding()
    }
}

// Debug preview
#Preview {
    ContentView()
}
