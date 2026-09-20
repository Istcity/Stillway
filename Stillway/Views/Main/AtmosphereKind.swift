import SwiftUI

/// Generative visual mode — Endel-like atmospheres keyed to sound/context.
enum AtmosphereKind: String, Codable, CaseIterable, Sendable {
    case aurora
    case rain
    case lava
    case stream
    case mist
    case ember
    case snow
    case prism

    static func resolve(soundID: String?, context: AppContext) -> AtmosphereKind {
        switch soundID {
        case "silent_snow", "minka_library":
            return .snow
        case "healing_528hz", "sacred_om", "autumn_432hz":
            return .prism
        case "aurora_ocean", "night_forest", "moonlit_dunes":
            return .aurora
        case "tokyo_rain", "rain_window", "greenhouse_rain", "tin_roof_rain":
            return .rain
        case "istanbul_ferry", "kyoto_bamboo", "mossy_waterfall", "gong_bath":
            return .stream
        case "deep_train", "shinkansen", "tokyo_metro", "paris_metro":
            return .lava
        case "night_cafe", "hygge_night":
            return .ember
        case "study_cat":
            return .mist
        default:
            break
        }
        switch context {
        case .sleep: return .aurora
        case .focus: return .mist
        case .commute: return .lava
        case .reset: return .stream
        case .walking: return .prism
        case .deepWork: return .ember
        case .unknown: return .mist
        }
    }

    var symbol: String {
        switch self {
        case .aurora: return "sparkles"
        case .rain: return "cloud.rain.fill"
        case .lava: return "flame.fill"
        case .stream: return "water.waves"
        case .mist: return "aqi.medium"
        case .ember: return "sun.haze.fill"
        case .snow: return "snowflake"
        case .prism: return "rainbow"
        }
    }
}
