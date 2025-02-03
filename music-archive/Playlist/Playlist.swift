//
//  Playlist.swift
//  music-archive
//
//  Created by Ben Kamen on 2/3/25.
//

import Foundation
import SwiftUI

struct Playlist: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var tracks: [URL]
}

class PlaylistStore: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var currentPlaylist: Playlist?

    func createNewPlaylist(withTracks tracks: [URL], name: String = "New Playlist") {
        // Create a new playlist with the tracks in random order.
        let playlist = Playlist(name: name, tracks: tracks.shuffled())
        currentPlaylist = playlist
        playlists.append(playlist)
    }
    
    func loadPlaylist(_ playlist: Playlist) {
        currentPlaylist = playlist
    }
    
    func addFileToCurrentPlaylist(file: URL) {
        guard var current = currentPlaylist else { return }
        if !current.tracks.contains(file) {
            current.tracks.append(file)
            currentPlaylist = current
            if let index = playlists.firstIndex(where: { $0.id == current.id }) {
                playlists[index] = current
            }
        }
    }
    
    func moveFile(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        guard var current = currentPlaylist else { return }
        current.tracks.move(fromOffsets: offsets, toOffset: destination)
        currentPlaylist = current
        if let index = playlists.firstIndex(where: { $0.id == current.id }) {
            playlists[index] = current
        }
    }
}
