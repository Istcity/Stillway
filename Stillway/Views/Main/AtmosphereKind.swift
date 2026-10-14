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
    case neonSmoke
    case lavaTube
    case lightShow

    static func resolve(soundID: String?, context: AppContext) -> AtmosphereKind {
        switch soundID {
        case "neon_vapor":
            return .neonSmoke
        case "lava_tube":
            return .lavaTube
        case "prism_light":
            return .lightShow
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
        case .neonSmoke: return "smoke.fill"
        case .lavaTube: return "drop.fill"
        case .lightShow: return "rays"
        }
    }

    func titleKey() -> String {
        switch self {
        case .aurora: return "atmo_aurora"
        case .rain: return "atmo_rain"
        case .lava: return "atmo_lava"
        case .stream: return "atmo_stream"
        case .mist: return "atmo_mist"
        case .ember: return "atmo_ember"
        case .snow: return "atmo_snow"
        case .prism: return "atmo_prism"
        case .neonSmoke: return "atmo_neon_smoke"
        case .lavaTube: return "atmo_lava_tube"
        case .lightShow: return "atmo_light_show"
        }
    }

    func displayName(using lm: LocalizationManager) -> String {
        let key = titleKey()
        let localized = lm.string(key)
        if !localized.contains("_") {
            return localized
        }
        switch self {
        case .neonSmoke:
            return lm.currentLanguage == .tr ? "Siber Duman" : (lm.currentLanguage == .ja ? "サイバースモーク" : (lm.currentLanguage == .fr ? "Fumée Cyber" : "Cyber Smoke"))
        case .lavaTube:
            return lm.currentLanguage == .tr ? "Lav Tüpü" : (lm.currentLanguage == .ja ? "ラバチューブ" : (lm.currentLanguage == .fr ? "Tube de Lave" : "Lava Tube"))
        case .lightShow:
            return lm.currentLanguage == .tr ? "Işık Oyunları" : (lm.currentLanguage == .ja ? "ライトショー" : (lm.currentLanguage == .fr ? "Jeux de Lumière" : "Light Show"))
        case .aurora:
            return lm.currentLanguage == .tr ? "Kutup Işıkları" : (lm.currentLanguage == .ja ? "極光オーロラ" : (lm.currentLanguage == .fr ? "Aurore Polaire" : "Polar Aurora"))
        case .rain:
            return lm.currentLanguage == .tr ? "Gece Yağmuru" : (lm.currentLanguage == .ja ? "夜の雨" : (lm.currentLanguage == .fr ? "Pluie Nocturne" : "Night Rain"))
        case .lava:
            return lm.currentLanguage == .tr ? "Hızlı Geçiş" : (lm.currentLanguage == .ja ? "新幹線光条" : (lm.currentLanguage == .fr ? "Transit Rapide" : "Hyper Transit"))
        case .stream:
            return lm.currentLanguage == .tr ? "Okyanus Sisi" : (lm.currentLanguage == .ja ? "海洋の霧" : (lm.currentLanguage == .fr ? "Brume Océanique" : "Ocean Mist"))
        case .mist:
            return lm.currentLanguage == .tr ? "Mist" : (lm.currentLanguage == .ja ? "ミスト" : (lm.currentLanguage == .fr ? "Brume" : "Mist"))
        case .ember:
            return lm.currentLanguage == .tr ? "Şömine Közü" : (lm.currentLanguage == .ja ? "暖炉の残火" : (lm.currentLanguage == .fr ? "Braises de Foyer" : "Hearth Embers"))
        case .snow:
            return lm.currentLanguage == .tr ? "Sessiz Kar" : (lm.currentLanguage == .ja ? "静寂の雪" : (lm.currentLanguage == .fr ? "Neige Silencieuse" : "Silent Snow"))
        case .prism:
            return lm.currentLanguage == .tr ? "Prizma Halesi" : (lm.currentLanguage == .ja ? "プリズムハロ" : (lm.currentLanguage == .fr ? "Halo Prismatique" : "Prism Halo"))
        }
    }
}
