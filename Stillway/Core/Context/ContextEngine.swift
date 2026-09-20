import Foundation
import Observation
import SwiftData
import CoreLocation

@Observable
@MainActor
final class ContextEngine {
    let audioEngine = AudioEngine()
    let themeEngine = ThemeEngine()
    let locationManager = LocationManager.shared
    let geofenceManager = GeofenceManager()
    let motionClassifier = MotionClassifier()
    let sleepDetector = SleepDetector()
    let stations = StationDatabase.shared
    let breathing = HapticBreathingEngine()
    let liveActivity = LiveActivityManager()

    var visitTracker: VisitTracker?

    var currentContext: AppContext = .unknown
    var triggerType: TriggerType = .manual
    var activeStationID: String?
    var latestDecision = ContextDecision(
        context: .unknown,
        shouldAutoStart: false,
        triggerType: .manual,
        suggestedSoundID: "tokyo_rain",
        confidence: 0
    )

    var selectedTimerMinutes: Int? = 30
    var weatherTemp: String = "20°C"
    var weatherSymbol: String = "cloud.sun.fill"
    var cityName: String = ""
    var expectedWeatherSummary: String = "+3s 19°C"
    var expectedWeatherCondition: String = "Parçalı Bulutlu"

    var weatherDisplayBadge: String {
        if !cityName.isEmpty {
            return "\(cityName) • \(expectedWeatherSummary) \(expectedWeatherCondition)"
        } else {
            return "\(expectedWeatherSummary) • \(expectedWeatherCondition)"
        }
    }
    var showSettings = false
    var showPlaces = false
    var showSounds = false
    var showPlaceLabel = false
    var showAutoBanner = false
    var toast: String?
    var pendingLabelPlace: UserPlace? { visitTracker?.pendingLabelPlace }

    var audio: AudioEngine { audioEngine }
    var theme: ThemeEngine { themeEngine }
    var location: LocationManager { locationManager }
    var geofence: GeofenceManager { geofenceManager }
    var motion: MotionClassifier { motionClassifier }
    var localization = LocalizationManager()

    private var modelContext: ModelContext?
    private var isConfigured = false
    private var tickTask: Task<Void, Never>?
    private var placeObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        visitTracker = VisitTracker(modelContext: modelContext)
        guard !isConfigured else { return }
        isConfigured = true
        geofenceManager.setup()
        locationManager.onVisit = { [weak self] visit in
            self?.handleVisit(visit)
        }
        locationManager.onSignificantChange = { [weak self] location in
            self?.handleLocation(location)
        }
        geofenceManager.onTransitEntry = { [weak self] station in
            self?.handleStationEnter(station)
        }
        placeObserver = NotificationCenter.default.addObserver(forName: .placeNeedsLabel, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.showPlaceLabel = true
            }
        }
        sleepObserver = NotificationCenter.default.addObserver(forName: .sleepPromptNeeded, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.toast = self.localization.string("notif_sleep")
                NotificationScheduler.shared.suggestSleep(body: self.localization.string("notif_sleep"))
            }
        }
        sleepDetector.onSleepPrompt = { [weak self] in
            guard let self else { return }
            self.toast = self.localization.string("notif_sleep")
            NotificationScheduler.shared.suggestSleep(body: self.localization.string("notif_sleep"))
        }
        NotificationScheduler.shared.configure()
        NotificationScheduler.shared.onStartSuggested = { [weak self] context in
            guard let self else { return }
            let soundID = self.latestDecision.context == context
                ? self.latestDecision.suggestedSoundID
                : context.defaultSoundID
            if let sound = Sound.find(soundID) {
                self.startManually(context: context, sound: sound)
            }
        }
        NotificationScheduler.shared.onOpenPlaceLabel = { [weak self] in
            self?.showPlaceLabel = true
        }
        motionClassifier.start()
        locationManager.startAllServices()
        sleepDetector.startMonitoring(motion: motionClassifier, location: locationManager)
        Task { await liveActivity.endAllStale() }
        startTicker()
    }

    func startServices(modelContext: ModelContext) {
        configure(modelContext: modelContext)
    }

    func unlockAllFeaturesForTesting() {
        guard let modelContext else { return }
        let prefs = (try? modelContext.fetch(FetchDescriptor<UserPreferences>()))?.first
            ?? {
                let created = UserPreferences()
                modelContext.insert(created)
                return created
            }()
        prefs.isPro = true
        try? modelContext.save()
    }

    func prepareDefaultAtmosphereIfNeeded() {
        if audioEngine.primarySound == nil {
            let sound = Sound.find("tokyo_rain") ?? Sound.library[4]
            audioEngine.primarySound = sound
            currentContext = sound.context
            themeEngine.setImmediate(sound.context)
        }
    }

    func startManually(context: AppContext, sound: Sound) {
        currentContext = context
        triggerType = .manual
        themeEngine.apply(context: context)
        audioEngine.primarySound = sound
        audioEngine.setTimer(minutes: selectedTimerMinutes)
        audioEngine.play(sound: sound, fadeDuration: 2.0)
        if let minutes = selectedTimerMinutes {
            audioEngine.startJourneyArc(minutes: Double(minutes))
        }
        if !audioEngine.isUsingFileBed {
            toast = localization.string("toast_demo_noise")
        }
        if let prefs = fetchPreferences(), prefs.hapticBreathingEnabled {
            breathing.start()
        }
        liveActivity.start(
            contextName: localization.string(context.localizationKey),
            soundName: localization.string(sound.localizationKey),
            totalMinutes: selectedTimerMinutes ?? 30,
            accentHex: Self.accentHex(for: context),
            atmosphereKind: AtmosphereKind.resolve(soundID: sound.id, context: context).rawValue
        )
        if let modelContext {
            modelContext.insert(CommutSession(context: context, soundID: sound.id, triggeredAutomatically: false))
        }
        NotificationCenter.default.post(name: .contextDidChange, object: context.rawValue)
    }

    func stop() {
        audioEngine.stop()
        liveActivity.end()
        breathing.stop()
        triggerType = .manual
        toast = localization.string("toast_stopped")
    }

    func handleStartStop(preferences: UserPreferences?) {
        if audioEngine.isPlaying {
            stop()
        } else {
            let sound = Sound.find(preferences?.lastSoundID ?? audioEngine.primarySound?.id ?? "tokyo_rain") ?? Sound.library[4]
            startManually(context: sound.context, sound: sound)
            toast = localization.string("toast_started")
            HapticEngine.tap()
        }
    }

    func selectSound(_ sound: Sound, isPro: Bool, preferences: UserPreferences?) {
        if !sound.isFree && !isPro {
            showSettings = true
            return
        }
        audioEngine.primarySound = sound
        preferences?.lastSoundID = sound.id
        themeEngine.apply(context: sound.context)
        if audioEngine.isPlaying {
            audioEngine.play(sound: sound, fadeDuration: 2.4)
            if !audioEngine.isUsingFileBed {
                toast = localization.string("toast_demo_noise")
            }
            liveActivity.update(
                contextName: localization.string(sound.context.localizationKey),
                soundName: localization.string(sound.localizationKey),
                remainingSeconds: audioEngine.remainingSeconds,
                accentHex: Self.accentHex(for: sound.context),
                isPlaying: true,
                atmosphereKind: AtmosphereKind.resolve(soundID: sound.id, context: sound.context).rawValue
            )
        }
        HapticEngine.select()
    }

    func selectTimer(_ minutes: Int?) {
        selectedTimerMinutes = minutes
        audioEngine.setTimer(minutes: minutes)
        HapticEngine.select()
    }

    func completeOnboarding() {
        Task {
            await requestStartupPermissions()
        }
    }

    /// Ask for location + motion + notifications once, persist that we asked.
    func requestStartupPermissions() async {
        let prefs = fetchPreferences()
        await PermissionBootstrap.requestAll(
            location: locationManager,
            motion: motionClassifier,
            preferences: prefs
        ) { [weak self] in
            try? self?.modelContext?.save()
        }
    }

    private func startTicker() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.audioEngine.updateJourneyArc()
                self?.publishWidgetState()
                if let self, self.audioEngine.isPlaying {
                    self.liveActivity.update(remainingSeconds: self.audioEngine.remainingSeconds)
                }
            }
        }
    }

    private func handleVisit(_ visit: CLVisit) {
        visitTracker?.process(visit: visit)
        if visitTracker?.pendingLabelPlace != nil {
            showPlaceLabel = true
        }
        reevaluate()
    }

    private func handleLocation(_ location: CLLocation) {
        geofenceManager.refresh(near: location.coordinate)
        if let prefs = fetchPreferences() {
            prefs.lastKnownLatitude = location.coordinate.latitude
            prefs.lastKnownLongitude = location.coordinate.longitude
        }
        reverseGeocode(location)
        fetchWeatherForecast(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        reevaluate()
    }

    private func handleStationEnter(_ station: Station) {
        activeStationID = station.id
        reevaluate()
    }

    private func reevaluate() {
        guard let modelContext else { return }
        let places = (try? modelContext.fetch(FetchDescriptor<UserPlace>())) ?? []
        let preferences = fetchPreferences() ?? {
            let created = UserPreferences()
            modelContext.insert(created)
            return created
        }()
        guard preferences.contextDetectionEnabled else { return }

        let nearest = nearestPlace(places: places)
        sleepDetector.configure(preferences: preferences, homePlace: places.first(where: { $0.label == .home }))

        let decision = evaluate(
            headphones: audioEngine.isHeadphonesConnected,
            stationID: activeStationID,
            activity: motionClassifier.currentActivity,
            trainProbability: motionClassifier.trainProbability,
            nearest: nearest,
            preferences: preferences,
            isPro: preferences.isPro,
            isHorizontal: motionClassifier.isPhoneHorizontal
        )
        latestDecision = decision
        currentContext = decision.context
        triggerType = decision.triggerType
        themeEngine.apply(context: decision.context)

        if decision.shouldAutoStart, !audioEngine.isPlaying, let sound = Sound.find(decision.suggestedSoundID) {
            startManually(context: decision.context, sound: sound)
            showAutoBanner = true
            NotificationCenter.default.post(name: .autoSessionTriggered, object: decision.context.rawValue)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                self?.showAutoBanner = false
            }
        } else if !decision.shouldAutoStart, decision.triggerType == .suggested, !audioEngine.isPlaying {
            switch decision.context {
            case .commute:
                NotificationScheduler.shared.suggestCommute(body: localization.string("notif_commute"))
            case .focus:
                NotificationScheduler.shared.suggestFocus(body: localization.string("notif_focus"))
            case .sleep:
                NotificationScheduler.shared.suggestSleep(body: localization.string("notif_sleep"))
            default:
                break
            }
        }

        if let currentLocation = locationManager.currentLocation {
            sleepDetector.checkSleepConditions(
                preferences: preferences,
                places: places,
                currentLocation: currentLocation,
                motionActivity: motionClassifier.latestActivity,
                isPhoneHorizontal: motionClassifier.isPhoneHorizontal
            )
        }
    }

    private func evaluate(
        headphones: Bool,
        stationID: String?,
        activity: ActivityState,
        trainProbability: Double,
        nearest: UserPlace?,
        preferences: UserPreferences,
        isPro: Bool,
        isHorizontal: Bool
    ) -> ContextDecision {
        let hour = Calendar.current.component(.hour, from: Date())
        if stationID != nil, headphones {
            return ContextDecision(context: .commute, shouldAutoStart: isPro, triggerType: headphones ? .automatic : .suggested, suggestedSoundID: "tokyo_metro", confidence: 0.92)
        }
        // Heuristic rail/metro score (stand-in for TrainClassifier.mlmodel).
        if trainProbability >= 0.62, headphones || activity == .automotive {
            return ContextDecision(
                context: .commute,
                shouldAutoStart: isPro && headphones,
                triggerType: headphones ? .automatic : .suggested,
                suggestedSoundID: "deep_train",
                confidence: min(0.9, 0.55 + trainProbability * 0.4)
            )
        }
        if activity == .automotive {
            return ContextDecision(context: .commute, shouldAutoStart: isPro && headphones, triggerType: headphones ? .automatic : .suggested, suggestedSoundID: "shinkansen", confidence: 0.8)
        }
        if preferences.sleepModeEnabled,
           nearest?.label == .home,
           hour >= preferences.sleepStartHour || hour < preferences.sleepEndHour,
           activity.isStationary,
           isHorizontal {
            return ContextDecision(context: .sleep, shouldAutoStart: isPro, triggerType: .suggested, suggestedSoundID: "night_forest", confidence: 0.78)
        }
        if let nearest, nearest.label == .work || nearest.label == .library, (9...18).contains(hour) {
            return ContextDecision(context: .focus, shouldAutoStart: isPro && nearest.autoStartEnabled && headphones, triggerType: nearest.autoStartEnabled ? .automatic : .suggested, suggestedSoundID: nearest.defaultSoundID ?? "tokyo_rain", confidence: 0.74)
        }
        if activity == .walking, headphones {
            return ContextDecision(context: .reset, shouldAutoStart: false, triggerType: .suggested, suggestedSoundID: "kyoto_bamboo", confidence: 0.6)
        }
        return ContextDecision(context: .unknown, shouldAutoStart: false, triggerType: .manual, suggestedSoundID: preferences.lastSoundID, confidence: 0.2)
    }

    private func fetchPreferences() -> UserPreferences? {
        guard let modelContext else { return nil }
        return try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first
    }

    private func publishWidgetState() {
        let defaults = UserDefaults(suiteName: "group.com.sinannergiz.stillway")
        defaults?.set(localization.string(themeEngine.currentContext.localizationKey), forKey: "contextName")
        defaults?.set(localization.string((audioEngine.primarySound ?? Sound.find("tokyo_rain")!).localizationKey), forKey: "soundName")
        defaults?.set(TimerRing.format(audioEngine.remainingSeconds), forKey: "remaining")
        defaults?.set(audioEngine.isPlaying, forKey: "isPlaying")
    }

    private func nearestPlace(places: [UserPlace]) -> UserPlace? {
        guard let current = locationManager.currentLocation else { return nil }
        return places.min { $0.distance(to: current) < $1.distance(to: current) }.flatMap { place in
            place.distance(to: current) < 150 ? place : nil
        }
    }

    func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let p = placemarks?.first else { return }
            let city = p.subLocality ?? p.locality ?? p.administrativeArea ?? ""
            Task { @MainActor in
                self.cityName = city
            }
        }
    }

    func fetchWeatherForecast(latitude: Double, longitude: Double) {
        // Önümüzdeki birkaç saat içinde beklenen hava durumunu çek
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&hourly=temperature_2m,weather_code&forecast_hours=6") else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                struct ForecastResp: Decodable {
                    struct Hourly: Decodable {
                        let time: [String]
                        let temperature_2m: [Double]
                        let weather_code: [Int]
                    }
                    let hourly: Hourly
                }
                let decoded = try JSONDecoder().decode(ForecastResp.self, from: data)
                // 2-3 saat sonrasının beklenen tahmini (index 2 veya 3)
                let targetIndex = min(2, max(0, decoded.hourly.temperature_2m.count - 1))
                let expTemp = Int(round(decoded.hourly.temperature_2m[targetIndex]))
                let expCode = decoded.hourly.weather_code[targetIndex]

                let sym: String
                let condKey: String
                switch expCode {
                case 0:
                    sym = "sun.max.fill"
                    condKey = "weather_clear"
                case 1, 2:
                    sym = "cloud.sun.fill"
                    condKey = "weather_partly_cloudy"
                case 3:
                    sym = "cloud.fill"
                    condKey = "weather_cloudy"
                case 45, 48:
                    sym = "cloud.fog.fill"
                    condKey = "weather_fog"
                case 51...67, 80...82:
                    sym = "cloud.rain.fill"
                    condKey = "weather_rain"
                case 71...77, 85, 86:
                    sym = "snowflake"
                    condKey = "weather_snow"
                case 95...99:
                    sym = "cloud.bolt.rain.fill"
                    condKey = "weather_storm"
                default:
                    sym = "cloud.sun.fill"
                    condKey = "weather_clear"
                }

                await MainActor.run {
                    self.weatherTemp = "\(expTemp)°C"
                    self.weatherSymbol = sym
                    let hrSuffix = self.localization.string("weather_in_3h")
                    self.expectedWeatherSummary = "\(hrSuffix) \(expTemp)°C"
                    self.expectedWeatherCondition = self.localization.string(condKey)
                }
            } catch {
                // Hata durumunda varsayılan tahmin korunur
            }
        }
    }

    private static func accentHex(for context: AppContext) -> String {
        switch context {
        case .commute: return "4169E1"
        case .focus: return "0A84FF"
        case .sleep: return "5E5CE6"
        case .reset: return "FF9F0A"
        case .walking: return "30D158"
        case .deepWork: return "FF453A"
        case .unknown: return "8A8A8E"
        }
    }
}

struct ContextDecision: Equatable {
    var context: AppContext
    var shouldAutoStart: Bool
    var triggerType: TriggerType
    var suggestedSoundID: String
    var confidence: Double
}

typealias StillwayRuntime = ContextEngine
