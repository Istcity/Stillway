import Foundation
import Observation
import SwiftUI

@Observable
final class LocalizationManager {
    var currentLanguage: LanguageCode {
        didSet {
            loadBundle()
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
            NotificationCenter.default.post(name: .languageDidChange, object: currentLanguage.rawValue)
        }
    }

    var selectedLanguage: String {
        get { currentLanguage.rawValue }
        set { currentLanguage = LanguageCode(rawValue: newValue) ?? .en }
    }

    var current: LanguageCode { currentLanguage }
    var locale: Locale { currentLanguage.locale }

    private var bundle: Bundle = .main

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey),
           let code = LanguageCode(rawValue: stored) {
            currentLanguage = code
        } else {
            currentLanguage = LanguageCode.detect()
        }
        loadBundle()
    }

    func string(_ key: String) -> String {
        _ = currentLanguage // Registers dependency for SwiftUI Observation framework
        let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        if value != key && !value.contains("_") { return value }
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let english = Bundle(path: path) {
            let val = english.localizedString(forKey: key, value: key, table: "Localizable")
            if val != key && !val.contains("_") { return val }
        }
        return cleanFallback(for: key)
    }

    private func cleanFallback(for key: String) -> String {
        switch key {
        case "atmo_mist":
            return currentLanguage == .tr ? "Mist" : (currentLanguage == .ja ? "ミスト" : (currentLanguage == .fr ? "Brume" : "Mist"))
        case "atmo_neon_smoke":
            return currentLanguage == .tr ? "Siber Duman" : (currentLanguage == .ja ? "サイバースモーク" : (currentLanguage == .fr ? "Fumée Cyber" : "Cyber Smoke"))
        case "atmo_lava_tube":
            return currentLanguage == .tr ? "Lav Tüpü" : (currentLanguage == .ja ? "ラバチューブ" : (currentLanguage == .fr ? "Tube de Lave" : "Lava Tube"))
        case "atmo_light_show":
            return currentLanguage == .tr ? "Işık Oyunları" : (currentLanguage == .ja ? "ライトショー" : (currentLanguage == .fr ? "Jeux de Lumière" : "Light Show"))
        case "atmo_aurora":
            return currentLanguage == .tr ? "Kutup Işıkları" : (currentLanguage == .ja ? "極光オーロラ" : (currentLanguage == .fr ? "Aurore Polaire" : "Polar Aurora"))
        case "atmo_rain":
            return currentLanguage == .tr ? "Gece Yağmuru" : (currentLanguage == .ja ? "夜の雨" : (currentLanguage == .fr ? "Pluie Nocturne" : "Night Rain"))
        case "atmo_lava":
            return currentLanguage == .tr ? "Hızlı Geçiş" : (currentLanguage == .ja ? "新幹線光条" : (currentLanguage == .fr ? "Transit Rapide" : "Hyper Transit"))
        case "atmo_stream":
            return currentLanguage == .tr ? "Okyanus Sisi" : (currentLanguage == .ja ? "海洋の霧" : (currentLanguage == .fr ? "Brume Océanique" : "Ocean Mist"))
        case "atmo_ember":
            return currentLanguage == .tr ? "Şömine Közü" : (currentLanguage == .ja ? "暖炉の残火" : (currentLanguage == .fr ? "Braises de Foyer" : "Hearth Embers"))
        case "atmo_snow":
            return currentLanguage == .tr ? "Sessiz Kar" : (currentLanguage == .ja ? "静寂の雪" : (currentLanguage == .fr ? "Neige Silencieuse" : "Silent Snow"))
        case "atmo_prism":
            return currentLanguage == .tr ? "Prizma Halesi" : (currentLanguage == .ja ? "プリズムハロ" : (currentLanguage == .fr ? "Halo Prismatique" : "Prism Halo"))
        case "atmo_auto":
            return currentLanguage == .tr ? "Otomatik" : (currentLanguage == .ja ? "自動" : (currentLanguage == .fr ? "Auto" : "Auto"))
        case "atmo_reset_auto":
            return currentLanguage == .tr ? "Sıfırla" : (currentLanguage == .ja ? "リセット" : (currentLanguage == .fr ? "Réinitialiser" : "Reset"))
        case "settings_atmosphere":
            return currentLanguage == .tr ? "Görsel Atmosfer & Temalar" : (currentLanguage == .ja ? "空間ビジュアル＆テーマ" : (currentLanguage == .fr ? "Atmosphères & Thèmes" : "Visual Atmosphere & Themes"))
        case "settings_atmosphere_title":
            return currentLanguage == .tr ? "Atmosfer Teması" : (currentLanguage == .ja ? "ビジュアルテーマ" : (currentLanguage == .fr ? "Thème Visuel" : "Atmosphere Theme"))
        case "settings_atmosphere_desc":
            return currentLanguage == .tr ? "Sesle otomatik değişir veya favori görsel temanızı sabitleyin." : (currentLanguage == .ja ? "音に合わせて自動変化、またはお好みのテーマを固定できます。" : (currentLanguage == .fr ? "Change avec le son ou fixez votre thème visuel préféré." : "Changes automatically with sound, or lock your favorite visual theme."))
        case "weather_clear":
            return currentLanguage == .tr ? "Açık" : (currentLanguage == .ja ? "快晴" : (currentLanguage == .fr ? "Dégagé" : "Clear"))
        case "weather_partly_cloudy":
            return currentLanguage == .tr ? "Parçalı Bulutlu" : (currentLanguage == .ja ? "晴れ時々曇り" : (currentLanguage == .fr ? "Partiellement Nuageux" : "Partly Cloudy"))
        case "weather_cloudy":
            return currentLanguage == .tr ? "Bulutlu" : (currentLanguage == .ja ? "曇り" : (currentLanguage == .fr ? "Nuageux" : "Cloudy"))
        case "weather_fog":
            return currentLanguage == .tr ? "Sisli" : (currentLanguage == .ja ? "霧" : (currentLanguage == .fr ? "Brouillard" : "Foggy"))
        case "weather_rain":
            return currentLanguage == .tr ? "Yağmurlu" : (currentLanguage == .ja ? "雨" : (currentLanguage == .fr ? "Pluvieux" : "Rainy"))
        case "weather_snow":
            return currentLanguage == .tr ? "Kar Yağışlı" : (currentLanguage == .ja ? "雪" : (currentLanguage == .fr ? "Neige" : "Snowy"))
        case "weather_storm":
            return currentLanguage == .tr ? "Fırtına" : (currentLanguage == .ja ? "雷雨" : (currentLanguage == .fr ? "Orage" : "Thunderstorm"))
        case "weather_in_3h":
            return currentLanguage == .tr ? "+3s" : (currentLanguage == .ja ? "+3時間" : (currentLanguage == .fr ? "+3h" : "+3h"))
        default:
            var cleaned = key
            for p in ["atmo_", "snd_", "ctx_", "settings_", "weather_"] {
                if cleaned.hasPrefix(p) {
                    cleaned = String(cleaned.dropFirst(p.count))
                    break
                }
            }
            return cleaned.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func loadBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let loaded = Bundle(path: path) {
            bundle = loaded
        } else {
            bundle = .main
        }
    }

    static func autoDetect() -> String {
        LanguageCode.detect().rawValue
    }

    private static let storageKey = "selectedLanguage"
}

private struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager()
}

extension EnvironmentValues {
    var lm: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
