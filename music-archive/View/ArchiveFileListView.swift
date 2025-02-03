import SwiftUI
import AppKit

struct ArchiveFileListView: View {
    @ObservedObject var metadataSearch: MetadataSearch
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var eventLogger: EventLogger
    @ObservedObject var playlistStore: PlaylistStore

    var body: some View {
        List(metadataSearch.audioFiles, id: \.self) { file in
            HStack {
                Text(file.lastPathComponent)
                Spacer()
                StarRatingView(file: file)
            }
            .contentShape(Rectangle())
            .onTapGesture {
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
                Button("Add to Playlist") {
                    playlistStore.addFileToCurrentPlaylist(file: file)
                    eventLogger.log("Added \(file.lastPathComponent) to playlist", isError: false)
                }
            }
        }
    }
}
