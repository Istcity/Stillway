import Foundation

enum SoundRegion: String, Codable, Sendable {
    case JP, FR, UK, US, TR, NATURE, URBAN

    var flag: String {
        switch self {
        case .JP: return "🇯🇵"
        case .FR: return "🇫🇷"
        case .UK: return "🇬🇧"
        case .US: return "🇺🇸"
        case .TR: return "🇹🇷"
        case .NATURE: return "🌿"
        case .URBAN: return "🏙"
        }
    }
}

/// Selectable binaural / carrier tone layer for focus and sleep mixes.
enum BinauralTone: String, CaseIterable, Codable, Sendable, Identifiable, Hashable {
    case off
    case delta
    case theta
    case alpha
    case beta

    var id: String { rawValue }

    /// Beat frequency in Hz (carrier offset). `off` is silent.
    var beatHz: Double {
        switch self {
        case .off: return 0
        case .delta: return 2.5
        case .theta: return 6
        case .alpha: return 10
        case .beta: return 16
        }
    }

    var localizationKey: String {
        switch self {
        case .off: return "binaural_off"
        case .delta: return "binaural_delta"
        case .theta: return "binaural_theta"
        case .alpha: return "binaural_alpha"
        case .beta: return "binaural_beta"
        }
    }
}

struct Sound: Identifiable, Equatable, Hashable, Codable, Sendable {
    let id: String
    let localizationKey: String
    let fileName: String
    let context: AppContext
    let region: SoundRegion
    let isFree: Bool
    let defaultVolume: Float
    let title: String
    let subtitle: String

    var bundleResource: String { fileName }

    func localizedTitle(using lm: LocalizationManager) -> String {
        let val = lm.string(localizationKey)
        return val == localizationKey ? title : val
    }

    func localizedSubtitle(using lm: LocalizationManager) -> String {
        let subKey = "\(localizationKey)_sub"
        let val = lm.string(subKey)
        return val == subKey ? subtitle : val
    }

    /// SF Symbol used in the sound picker and mixer.
    var iconName: String {
        switch id {
        case "tokyo_metro", "paris_metro":
            return "tram.fill"
        case "shinkansen", "deep_train":
            return "train.side.front.car"
        case "istanbul_ferry":
            return "ferry.fill"
        case "tokyo_rain", "rain_window":
            return "cloud.rain.fill"
        case "night_cafe":
            return "cup.and.saucer.fill"
        case "minka_library":
            return "books.vertical.fill"
        case "kyoto_bamboo":
            return "leaf.fill"
        case "temple_bell":
            return "bell.fill"
        case "night_forest":
            return "tree.fill"
        case "aurora_ocean":
            return "moon.stars.fill"
        case "silent_snow":
            return "snowflake"
        case "moonlit_dunes":
            return "moon.circle.fill"
        case "hygge_night":
            return "fireplace.fill"
        case "greenhouse_rain":
            return "leaf.arrow.triangle.circlepath"
        case "study_cat":
            return "book.closed.fill"
        case "tin_roof_rain":
            return "cloud.heavyrain.fill"
        case "sacred_om":
            return "circle.hexagongrid.fill"
        case "gong_bath":
            return "bell.and.waves.left.and.right.fill"
        case "mossy_waterfall":
            return "water.waves.and.arrow.down"
        case "autumn_432hz":
            return "flame.fill"
        case "healing_528hz":
            return "heart.circle.fill"
        default:
            return "waveform"
        }
    }

    static let library: [Sound] = [
        Sound(id: "tokyo_metro", localizationKey: "snd_tokyo_metro", fileName: "tokyo_metro", context: .commute, region: .JP, isFree: false, defaultVolume: 0.7, title: "Yeraltı Tüneli", subtitle: "Kemerli tünel sıcaklığı ve akustik derinlik"),
        Sound(id: "deep_train", localizationKey: "snd_deep_train", fileName: "deep_train", context: .commute, region: .URBAN, isFree: true, defaultVolume: 0.7, title: "Gece Ekspresi", subtitle: "Hipnotik demir raylar ve fener sıcaklığı"),
        Sound(id: "shinkansen", localizationKey: "snd_shinkansen", fileName: "shinkansen", context: .commute, region: .JP, isFree: false, defaultVolume: 0.7, title: "Aerodinamik Ray", subtitle: "Manyetik hat akışı ve fütüristik hız dinginliği"),
        Sound(id: "paris_metro", localizationKey: "snd_paris_metro", fileName: "paris_metro", context: .commute, region: .FR, isFree: false, defaultVolume: 0.7, title: "Şehir Ritmi", subtitle: "Metro tünellerinin hafif titreşimi ve yankısı"),
        Sound(id: "istanbul_ferry", localizationKey: "snd_istanbul_ferry", fileName: "istanbul_ferry", context: .commute, region: .TR, isFree: false, defaultVolume: 0.65, title: "Boğaz Vapuru", subtitle: "Marmara dalgaları ve martıların dingin ezgisi"),
        
        Sound(id: "tokyo_rain", localizationKey: "snd_tokyo_rain", fileName: "tokyo_rain", context: .focus, region: .JP, isFree: true, defaultVolume: 0.6, title: "Gece Yağmuru", subtitle: "Şehir ışıkları altında yumuşak yağmur taneleri"),
        Sound(id: "night_cafe", localizationKey: "snd_night_cafe", fileName: "night_cafe", context: .focus, region: .URBAN, isFree: false, defaultVolume: 0.5, title: "Kadife Salon", subtitle: "Sıcak fincan tınıları ve fısıltılı kahve dinginliği"),
        Sound(id: "minka_library", localizationKey: "snd_minka_library", fileName: "minka_library", context: .focus, region: .JP, isFree: false, defaultVolume: 0.45, title: "Sessiz Mabed", subtitle: "Eski ahşap raflar ve derin odaklanma sessizliği"),
        Sound(id: "study_cat", localizationKey: "snd_study_cat", fileName: "study_cat", context: .focus, region: .URBAN, isFree: true, defaultVolume: 0.55, title: "Gece Çalışması & Kedi", subtitle: "Yumuşak mırıltı ve lo-fi gece çalışma huzuru"),
        Sound(id: "greenhouse_rain", localizationKey: "snd_greenhouse_rain", fileName: "greenhouse_rain", context: .focus, region: .NATURE, isFree: true, defaultVolume: 0.6, title: "Sera Yağmuru", subtitle: "Botanik bahçesi camına vuran yağmur damlaları"),
        Sound(id: "tin_roof_rain", localizationKey: "snd_tin_roof_rain", fileName: "tin_roof_rain", context: .focus, region: .NATURE, isFree: false, defaultVolume: 0.65, title: "Teneke Çatıda Yağmur", subtitle: "Kırsal sığınağın tavanında ritmik yağmur akoru"),
        Sound(id: "autumn_432hz", localizationKey: "snd_autumn_432hz", fileName: "autumn_432hz", context: .focus, region: .NATURE, isFree: false, defaultVolume: 0.55, title: "432Hz Sonbahar Şöminesi", subtitle: "Çıtırdayan odunlar ve 432Hz zihinsel berraklık"),

        Sound(id: "kyoto_bamboo", localizationKey: "snd_kyoto_bamboo", fileName: "kyoto_bamboo", context: .walking, region: .JP, isFree: false, defaultVolume: 0.55, title: "Güneşli Esinti", subtitle: "Ilık güneş huzmeleri ve ferahlatıcı yaz rüzgarı"),
        Sound(id: "rain_window", localizationKey: "snd_rain_window", fileName: "rain_window", context: .reset, region: .NATURE, isFree: true, defaultVolume: 0.6, title: "Kıyı Dalgaları", subtitle: "Kıyıya vuran dalgalar ve deniz esintisi"),
        Sound(id: "temple_bell", localizationKey: "snd_temple_bell", fileName: "temple_bell", context: .reset, region: .JP, isFree: false, defaultVolume: 0.5, title: "Zen Tapınak Çanı", subtitle: "Uzak dağ çanının derin titreşimi ve zihin arınması"),
        Sound(id: "mossy_waterfall", localizationKey: "snd_mossy_waterfall", fileName: "mossy_waterfall", context: .reset, region: .NATURE, isFree: false, defaultVolume: 0.6, title: "Yosunlu Şelale", subtitle: "Orman içi mağarada kristal su dökülüşü"),
        Sound(id: "gong_bath", localizationKey: "snd_gong_bath", fileName: "gong_bath", context: .reset, region: .NATURE, isFree: false, defaultVolume: 0.5, title: "Gong Dinginliği", subtitle: "Akustik rezonans ile bedeni ve zihni sıfırlama"),
        Sound(id: "sacred_om", localizationKey: "snd_sacred_om", fileName: "sacred_om", context: .reset, region: .NATURE, isFree: false, defaultVolume: 0.5, title: "Kutsal Om Dronu", subtitle: "Derin nefes ve köklenme frekansı"),
        Sound(id: "healing_528hz", localizationKey: "snd_healing_528hz", fileName: "healing_528hz", context: .reset, region: .NATURE, isFree: false, defaultVolume: 0.55, title: "528Hz Şifa Frekansı", subtitle: "Hücresel rahatlama ve solfeggio dinginliği"),
        Sound(id: "hygge_night", localizationKey: "snd_hygge_night", fileName: "hygge_night", context: .reset, region: .NATURE, isFree: false, defaultVolume: 0.5, title: "İskandinav Gecesi", subtitle: "Sıcak battaniye ve kış gecesi huzuru"),

        Sound(id: "night_forest", localizationKey: "snd_night_forest", fileName: "night_forest", context: .sleep, region: .NATURE, isFree: false, defaultVolume: 0.4, title: "Gece Ormanı", subtitle: "Ağaçların hafif uğultusu ve derin uyku atmosferi"),
        Sound(id: "aurora_ocean", localizationKey: "snd_aurora_ocean", fileName: "aurora_ocean", context: .sleep, region: .NATURE, isFree: true, defaultVolume: 0.6, title: "Kuzey Işıkları & Deniz", subtitle: "Yıldızlı kutup göğü ve dingin okyanus yansıması"),
        Sound(id: "silent_snow", localizationKey: "snd_silent_snow", fileName: "silent_snow", context: .sleep, region: .NATURE, isFree: true, defaultVolume: 0.5, title: "Sessiz Kar Vadisi", subtitle: "Yavaşça yağan kar taneleri ve mutlak sessizlik"),
        Sound(id: "moonlit_dunes", localizationKey: "snd_moonlit_dunes", fileName: "moonlit_dunes", context: .sleep, region: .NATURE, isFree: false, defaultVolume: 0.55, title: "Ay Işığında Kumullar", subtitle: "Çöl gecesinde esen serin rüzgar ve Samanyolu")
    ]

    static var freeLibrary: [Sound] { library.filter(\.isFree) }

    static func sounds(for context: AppContext) -> [Sound] {
        switch context {
        case .walking:
            return library.filter { $0.context == .reset || $0.context == .walking }
        case .deepWork:
            return library.filter { $0.context == .focus || $0.id == "deep_train" }
        case .unknown:
            return library
        default:
            return library.filter { $0.context == context }
        }
    }

    static func find(_ id: String) -> Sound? {
        library.first { $0.id == id }
    }
}

enum SoundLibrary {
    static let all = Sound.library
    static let freeIDs = Set(Sound.freeLibrary.map(\.id))
    static func sound(id: String) -> Sound? { Sound.find(id) }
    static func sounds(for context: AppContext) -> [Sound] { Sound.sounds(for: context) }
}
