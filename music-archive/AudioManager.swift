import AVFoundation
import SwiftUI
import SwiftyDropbox

@MainActor
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentFile: URL?
    @Published var isLoading = false

    private var player: AVAudioPlayer?
    
    // Play from a local file URL
    func playAudio(from file: URL) throws {
        do {
            stopAudio()
            player = try AVAudioPlayer(contentsOf: file)
            player?.delegate = self
            player?.play()
            isPlaying = true
            currentFile = file
        } catch let error as NSError {
            if error.code == 2003334207 {
                // Handle the "file not optimized" (or not fully downloaded) error
                print("File is not fully available (OSStatus error 2003334207)")
                
            } else {
                print("Failed to play audio: \(error)")
            }
        } catch {
            throw error
        }
    }
    
    func stopAudio() {
        player?.stop()
        isPlaying = false
        currentFile = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentFile = nil
    }
}
