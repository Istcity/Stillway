import Foundation

/// Testing switches for StoreKit and Feature gates.
/// In Freemium mode, features are gated unless unlocked via StoreKit, or bypassed via launch arguments.
enum StillwayTesting {
    static var unlockAllFeatures: Bool {
        if CommandLine.arguments.contains("-forcePaywall") {
            return false
        }
        if CommandLine.arguments.contains("-bypassPaywall") || CommandLine.arguments.contains("-unlockPro") {
            return true
        }
        return false
    }
}

