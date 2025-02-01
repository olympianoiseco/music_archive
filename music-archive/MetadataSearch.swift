import Foundation
import Combine

@MainActor
class MetadataSearch: NSObject, ObservableObject {
    @Published var audioFiles: [URL] = []
    private var query = NSMetadataQuery()

    override init() {
        super.init()
        setupQuery()
    }
    
    private func setupQuery() {
        query.searchScopes = [NSMetadataQueryUserHomeScope]
        query.predicate = NSPredicate(format: "kMDItemUserTags == 'archive'")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(queryUpdated),
                                               name: .NSMetadataQueryDidFinishGathering,
                                               object: query)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(queryUpdated),
                                               name: .NSMetadataQueryDidUpdate,
                                               object: query)
    }
    
    func startSearch() {
        if query.isStarted { query.stop() }
        audioFiles = []
        query.start()
    }
    
    @objc private func queryUpdated(notification: Notification) {
        query.disableUpdates()
        
        let results = query.results as? [NSMetadataItem] ?? []
        let newAudioFiles = results.compactMap { item -> URL? in
            guard
                let path = item.value(forAttribute: NSMetadataItemPathKey) as? String
            else { return nil }
            
            let fileURL = URL(fileURLWithPath: path)
            // Use UTType to verify this file is an audio file
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.contentTypeKey])
                if let contentType = resourceValues.contentType, contentType.conforms(to: .audio) {
                    return fileURL
                } else {
                    return nil
                }
            } catch {
                return nil
            }
            return nil
        }
        
        DispatchQueue.main.async {
            self.audioFiles = newAudioFiles
        }
        
        query.enableUpdates()
    }
}
