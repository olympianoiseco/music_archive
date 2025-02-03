import AVFoundation
import SwiftUI
import SwiftyDropbox

@MainActor
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentFile: URL?
    @Published var isLoading = false

    // Callbacks for logging, error, and finish events.
    var logEvent: ((String, Bool) -> Void)?
    var errorHandler: ((URL) -> Void)?
    var finishHandler: (() -> Void)?
    
    private var player: AVAudioPlayer?
    
    func playAudio(from file: URL) throws {
        do {
            stopAudio()
            player = try AVAudioPlayer(contentsOf: file)
            player?.delegate = self
            player?.play()
            isPlaying = true
            currentFile = file
            logEvent?("PLAY : \(file.lastPathComponent)", false)
        } catch let error as NSError {
            if error.code == 2003334207 {
                logEvent?("File not fully available: \(file.lastPathComponent)", true)
                errorHandler?(file)
            } else {
                logEvent?("Error playing \(file.lastPathComponent): \(error.localizedDescription)", true)
                errorHandler?(file)
            }
        } catch {
            logEvent?("Unknown error playing \(file.lastPathComponent)", true)
            errorHandler?(file)
            throw error
        }
    }
    
    func stopAudio() {
        player?.stop()
        isPlaying = false
        currentFile = nil
    }
    
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0
    }

    func restartCurrentTrack() {
        guard let player = player, let file = currentFile else { return }
        player.stop()
        player.currentTime = 0
        player.play()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentFile = nil
        finishHandler?()
    }
}
