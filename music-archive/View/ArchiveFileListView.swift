import SwiftUI
import AppKit

struct ArchiveFileListView: View {
    @ObservedObject var metadataSearch: MetadataSearch
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var eventLogger: EventLogger

    var body: some View {
        List(metadataSearch.audioFiles, id: \.self) { file in
            HStack {
                Text(file.lastPathComponent)
                Spacer()
                StarRatingView(file: file)
            }
            .contentShape(Rectangle()) // Make the entire row tappable.
            .onTapGesture {
                // Toggle pause/resume if this file is currently playing,
                // otherwise start playback of the new file.
                if audioManager.currentFile == file {
                    if audioManager.isPlaying {
                        audioManager.pauseAudio()
                    } else if audioManager.isPaused {
                        do {
                            try audioManager.playAudio(from: file)
                        } catch {
                            eventLogger.log("Failed to resume \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
                        }
                    }
                } else {
                    do {
                        try audioManager.playAudio(from: file)
                    } catch {
                        eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
                    }
                }
            }
            .contextMenu {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([file])
                }
            }
        }
    }
}


