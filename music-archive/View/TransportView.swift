//
//  TransportView.swift
//  music-archive
//
//  Created by Ben Kamen on 2/3/25.
//

import SwiftUI
import AppKit

struct TransportView: View {
    @ObservedObject var metadataSearch: MetadataSearch
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var eventLogger: EventLogger
    
    var startRandomPlayback: () -> Void
    var nextTrack: () -> Void
    var previousTrack: () -> Void
    
    var body: some View {
        VStack {
            // Control Panel
            VStack {
                PlayButton(metadataSearch: metadataSearch,
                           audioManager: audioManager,
                           eventLogger: eventLogger,
                           startPlaybackAction: startRandomPlayback)
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
            // Now Playing Section
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
            // Event Log
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
}
