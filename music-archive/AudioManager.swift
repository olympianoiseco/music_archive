import AVFoundation
import SwiftUI
import SwiftyDropbox

@MainActor
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentFile: URL?
    @Published var isLoading = false

    // Now expecting both a message and an error flag.
    var logEvent: ((String, Bool) -> Void)?
    
    private var player: AVAudioPlayer?
    
    func playAudio(from file: URL) throws {
        do {
            stopAudio()
            player = try AVAudioPlayer(contentsOf: file)
            player?.delegate = self
            player?.play()
            isPlaying = true
            currentFile = file
            logEvent?("Started playing: \(file.lastPathComponent)", false)
        } catch let error as NSError {
            if error.code == 2003334207 {
                logEvent?("File not fully available: \(file.lastPathComponent)", true)
                print("File is not fully available (OSStatus error 2003334207)")
            } else {
                logEvent?("Error playing \(file.lastPathComponent): \(error.localizedDescription)", true)
                print("Failed to play audio: \(error)")
            }
        } catch {
            logEvent?("Unknown error playing \(file.lastPathComponent)", true)
            throw error
        }
    }
    
    func stopAudio() {
        player?.stop()
        if let file = currentFile {
            logEvent?("Stopped playing: \(file.lastPathComponent)", false)
        }
        isPlaying = false
        currentFile = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let file = currentFile {
            logEvent?("Finished playing: \(file.lastPathComponent)", false)
        }
        isPlaying = false
        currentFile = nil
    }
}
