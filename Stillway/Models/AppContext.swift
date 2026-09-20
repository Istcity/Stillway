import Foundation

enum AppContext: Int, Codable, Comparable, CaseIterable, Identifiable, Sendable {
    case unknown = 0
    case commute = 1
    case focus = 2
    case sleep = 3
    case reset = 4
    case walking = 5
    case deepWork = 6

    var id: Int { rawValue }

    static func < (lhs: AppContext, rhs: AppContext) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var localizationKey: String {
        switch self {
        case .commute: return "ctx_commute"
        case .focus: return "ctx_focus"
        case .sleep: return "ctx_sleep"
        case .reset: return "ctx_reset"
        case .walking: return "ctx_walking"
        case .deepWork: return "ctx_deepwork"
        case .unknown: return "ctx_unknown"
        }
    }

    var defaultSoundID: String {
        switch self {
        case .commute: return "tokyo_metro"
        case .focus: return "tokyo_rain"
        case .sleep: return "night_forest"
        case .reset: return "rain_window"
        case .walking: return "kyoto_bamboo"
        case .deepWork: return "deep_train"
        case .unknown: return "tokyo_rain"
        }
    }

    var sfSymbol: String {
        switch self {
        case .commute: return "tram.fill"
        case .focus: return "brain.head.profile"
        case .sleep: return "moon.fill"
        case .reset: return "leaf.fill"
        case .walking: return "figure.walk"
        case .deepWork: return "flame.fill"
        case .unknown: return "waveform"
        }
    }

    var defaultTimerMinutes: Int {
        switch self {
        case .commute, .sleep, .deepWork: return 45
        case .focus, .unknown: return 30
        case .reset, .walking: return 15
        }
    }
}

enum TriggerType: String, Codable, Sendable {
    case automatic
    case suggested
    case manual
}
