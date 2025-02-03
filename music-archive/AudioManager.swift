import AVFoundation
import SwiftUI
import SwiftyDropbox

@MainActor
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentFile: URL?
    @Published var isLoading = false

    var logEvent: ((String, Bool) -> Void)?
    var errorHandler: ((URL) -> Void)?
    var finishHandler: (() -> Void)?
    
    private var player: AVAudioPlayer?
    
    func playAudio(from file: URL) throws {
        // If the same file is paused, resume playback.
        if let current = currentFile, current == file, isPaused {
            player?.play()
            isPlaying = true
            isPaused = false
            return
        }
        // Otherwise, start new playback.
        stopAudio(reset: true)
        do {
            player = try AVAudioPlayer(contentsOf: file)
            player?.delegate = self
            player?.play()
            isPlaying = true
            isPaused = false
            currentFile = file
            logEvent?("\(file.lastPathComponent)", false)
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
    
    func pauseAudio() {
        guard isPlaying, let file = currentFile else { return }
        player?.pause()
        isPlaying = false
        isPaused = true
    }
    
    func resumeAudio() {
        guard isPaused, let file = currentFile else { return }
        try? playAudio(from: file)
    }
    
    /// If reset is true, clear currentFile so that new playback always starts fresh.
    func stopAudio(reset: Bool = false) {
        player?.stop()
        isPlaying = false
        isPaused = false
        if reset { currentFile = nil }
    }
    
    func restartCurrentTrack() {
        guard let player = player, let file = currentFile else { return }
        player.stop()
        player.currentTime = 0
        player.play()
        isPlaying = true
        isPaused = false
    }
    
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        isPaused = false
        currentFile = nil
        finishHandler?()
    }
}
