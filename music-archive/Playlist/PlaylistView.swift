//
//  PlaylistView.swift
//  music-archive
//
//  Created by Ben Kamen on 2/3/25.
//

import SwiftUI
import AppKit

struct PlaylistView: View {
    @ObservedObject var playlistStore: PlaylistStore
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var eventLogger: EventLogger

    var body: some View {
        VStack(alignment: .leading) {
            if let playlist = playlistStore.currentPlaylist {
                Text("Playlist: \(playlist.name)")
                    .font(.headline)
                List {
                    ForEach(playlist.tracks, id: \.self) { file in
                        HStack {
                            Text(file.lastPathComponent)
                            Spacer()
                            StarRatingView(file: file)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            do {
                                try audioManager.playAudio(from: file)
                            } catch {
                                eventLogger.log("Failed to play \(file.lastPathComponent): \(error.localizedDescription)", isError: true)
                            }
                        }
                        .contextMenu {
                            Button("Show in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([file])
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        playlistStore.moveFile(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                Text("No playlist loaded")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: URL
    @Binding var listData: [URL]
    @Binding var dragItem: URL?

    func dropEntered(info: DropInfo) {
        guard let dragItem = dragItem,
              dragItem != item,
              let fromIndex = listData.firstIndex(of: dragItem),
              let toIndex = listData.firstIndex(of: item)
        else { return }
        
        if listData[toIndex] != dragItem {
            listData.move(fromOffsets: IndexSet(integer: fromIndex),
                          toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        self.dragItem = nil
        return true
    }
}
