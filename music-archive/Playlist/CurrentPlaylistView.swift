//
//  CurrentPlaylistView.swift
//  music-archive
//
//  Created by Ben Kamen on 2/3/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct CurrentPlaylistView: View {
    @ObservedObject var playlistStore: PlaylistStore
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var eventLogger: EventLogger
    
    // For drag–drop reordering within the current playlist.
    @State private var dragItem: URL? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            if let current = playlistStore.currentPlaylist {
                HStack {
                    Text("Playlist: \(current.name)")
                        .font(.headline)
                    // (Optionally add a rename button or context menu here.)
                }
                List {
                    ForEach(Array(current.tracks.enumerated()), id: \.element) { index, file in

                        FileInfo(file: file, audioManager: audioManager)
                            .onTapGesture {
                            do {
                                try audioManager.playAudio(from: file)
                            } catch {
                                eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
                            }
                        }
                        .onDrag {
                            self.dragItem = file
                            return NSItemProvider(object: file.absoluteString as NSString)
                        }
                        .onDrop(of: [UTType.plainText.identifier], delegate: PlaylistReorderDelegate(item: file, tracks: Binding(get: {
                            current.tracks
                        }, set: { newTracks in
                            var updated = current
                            updated.tracks = newTracks
                            playlistStore.currentPlaylist = updated
                            playlistStore.updatePlaylist(updated)
                        }), dragItem: $dragItem))
                        .contextMenu {
                            Button("Remove from Playlist") {
                                playlistStore.removeTrackFromCurrentPlaylist(track: file)
                                eventLogger.log("Removed \(file.lastPathComponent) from playlist", isError: false)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .id(current.id)
                .padding()
            } else {
                Text("No playlist loaded")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 300)
    }
}

struct PlaylistReorderDelegate: DropDelegate {
    let item: URL
    @Binding var tracks: [URL]
    @Binding var dragItem: URL?
    
    func dropEntered(info: DropInfo) {
        guard let dragItem = dragItem,
              dragItem != item,
              let fromIndex = tracks.firstIndex(of: dragItem),
              let toIndex = tracks.firstIndex(of: item) else { return }
        
        if tracks[toIndex] != dragItem {
            tracks.move(fromOffsets: IndexSet(integer: fromIndex),
                        toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        self.dragItem = nil
        return true
    }
}
