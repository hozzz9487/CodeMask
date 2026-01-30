
import AppKit
import os

enum SystemSound: Sendable {
    case tink
    case alert
    
    var soundName: String {
        switch self {
        case .tink: return "Tink"
        case .alert: return "Basso" // Common error/alert sound
        }
    }
}

protocol AudioServiceProtocol: Sendable {
    func prepare(sound: SystemSound)
    func playSystemSound(_ sound: SystemSound)
}

final class LiveAudioService: AudioServiceProtocol {
    
    private let cache = OSAllocatedUnfairLock(initialState: [SystemSound: NSSound]())
    
    func prepare(sound: SystemSound) {
        // Pre-load the sound
        if let nsSound = NSSound(named: sound.soundName) {
            cache.withLock { dict in
                dict[sound] = nsSound
            }
        }
    }
    
    func playSystemSound(_ sound: SystemSound) {
        // Try to get from cache first
        let cachedSound = cache.withLock { dict in
            dict[sound]
        }
        
        if let cachedSound {
            cachedSound.play()
        } else {
            // Fallback: load and play (and cache?)
            if let nsSound = NSSound(named: sound.soundName) {
                // If we want fire-and-forget, NSSound.play() is async in effect (audio engine handles it).
                nsSound.play()
                // Do we cache it now? Yes.
                cache.withLock { dict in
                    dict[sound] = nsSound
                }
            }
        }
    }
}
