import AVFoundation
import SwiftUI

@MainActor
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying: Bool = false
    @Published var currentFile: URL?
    
    private var player: AVAudioPlayer?

    func playAudio(from file: URL) {
        stopAudio()
        do {
            player = try AVAudioPlayer(contentsOf: file)
            player?.delegate = self
            player?.play()
            isPlaying = true
            currentFile = file
        } catch {
            print("Failed to play audio: \(error)")
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
