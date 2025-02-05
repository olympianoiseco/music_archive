import Foundation
import SwiftUI

struct Playlist: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var date: Date
    var tracks: [URL]
}

class PlaylistStore: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var currentPlaylist: Playlist?
    
    func createNewPlaylist(withTracks tracks: [URL], name: String? = nil) {
        let today = Date()
        let playlistName = name ?? "Untitled \(DateFormatter.dateOnly.string(from: today))"
        let playlist = Playlist(name: playlistName, date: today, tracks: tracks)
        currentPlaylist = playlist
        playlists.append(playlist)
        sortPlaylists()
    }
    
    func renamePlaylist(_ playlist: Playlist, newName: String) {
        var updated = playlist
        updated.name = newName
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = updated
        }
        if currentPlaylist?.id == playlist.id {
            currentPlaylist = updated
        }
        sortPlaylists()
    }
    
    func addTracksToCurrentPlaylist(newTracks: [URL]) {
        guard var current = currentPlaylist else { return }
        let filtered = newTracks.filter { !current.tracks.contains($0) }
        current.tracks.append(contentsOf: filtered)
        currentPlaylist = current
        updatePlaylist(current)
    }
    
    func removeTrackFromCurrentPlaylist(track: URL) {
        guard var current = currentPlaylist else { return }
        current.tracks.removeAll { $0 == track }
        currentPlaylist = current
        updatePlaylist(current)
    }
    
    func updatePlaylist(_ playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
        }
    }
    
    func addFile(to playlist: Playlist, file: URL) {
        var updated = playlist
        if !updated.tracks.contains(file) {
            updated.tracks.append(file)
            updatePlaylist(updated)
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = updated
            }
        }
    }
    
    private func sortPlaylists() {
        playlists.sort { $0.name < $1.name }
    }
}
