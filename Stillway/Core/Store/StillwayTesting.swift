import Foundation

/// Testing switches for StoreKit and Feature gates.
/// By default, Stillway enforces mandatory purchase (Hard Paywall) before access.
enum StillwayTesting {
    static var unlockAllFeatures: Bool {
        if CommandLine.arguments.contains("-forcePaywall") {
            return false
        }
        return true
    }
}
