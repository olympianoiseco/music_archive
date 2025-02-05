import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct PlaylistListView: View {
    @ObservedObject var playlistStore: PlaylistStore
    @ObservedObject var eventLogger: EventLogger
    @ObservedObject var metadataSearch: MetadataSearch
    @Binding var currentPlaylist: Playlist?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Playlists")
                .font(.headline)
            List {
                ForEach(playlistStore.playlists) { playlist in
                    HStack {
                        Text(playlist.name)
                        Spacer()
                    }
                    .padding(4)
                    .background(currentPlaylist?.id == playlist.id ? Color.blue.opacity(0.2) : Color.clear)
                    .onTapGesture {
                        currentPlaylist = playlist
                        eventLogger.log("Loaded playlist: \(playlist.name)", isError: false)
                    }
                    .onDrop(of: [UTType.plainText.identifier], delegate: PlaylistDropDelegate(playlist: playlist, playlistStore: playlistStore, eventLogger: eventLogger))
                }
            }
            .listStyle(PlainListStyle())
            HStack(alignment: .center, spacing: 4) {
                Button("Generate") {
                    let twentyTracks = Array(metadataSearch.audioFiles.shuffled().prefix(20))
                    playlistStore.createNewPlaylist(withTracks: twentyTracks, name: "Playlist \(DateFormatter.dateOnly.string(from: Date()))")
                }
                Button("New") {
                    playlistStore.createNewPlaylist(withTracks: [],
                                                    name: "Blank \(DateFormatter.dateOnly.string(from: Date()))")
                }
            }
        }
       
        .frame(width: 200)
       
    }
}

struct PlaylistDropDelegate: DropDelegate {
    let playlist: Playlist
    let playlistStore: PlaylistStore
    let eventLogger: EventLogger
    
    func performDrop(info: DropInfo) -> Bool {
        if let itemProvider = info.itemProviders(for: [UTType.plainText.identifier]).first {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
                if let data = data as? Data,
                   let urlString = String(data: data, encoding: .utf8),
                   let url = URL(string: urlString) {
                    DispatchQueue.main.async {
                        playlistStore.addFile(to: playlist, file: url)
                        eventLogger.log("Added \(url.lastPathComponent) to playlist \(playlist.name)", isError: false)
                    }
                }
            }
            return true
        }
        return false
    }
}

#Preview {
    let playlistStore = PlaylistStore()
    PlaylistListView(
        playlistStore: playlistStore,
        eventLogger: EventLogger(),
        metadataSearch: MetadataSearch(),
        currentPlaylist: .constant(nil)
    )
}
