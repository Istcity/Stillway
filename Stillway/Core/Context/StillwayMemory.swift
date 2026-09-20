import Foundation

enum StillwayMemory {
    private static let onboardingKey = "stillway.onboardingCompleted.v1"
    private static let languageKey = "stillway.selectedLanguage"
    private static let lastSoundKey = "stillway.lastSoundID"
    private static let lastTimerKey = "stillway.lastTimerMinutes"
    private static let permissionsRequestedKey = "stillway.permissionsRequested.v1"

    static var permissionsRequested: Bool {
        get { UserDefaults.standard.bool(forKey: permissionsRequestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: permissionsRequestedKey) }
    }

    static var onboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }

    static var selectedLanguage: String? {
        get { UserDefaults.standard.string(forKey: languageKey) }
        set { UserDefaults.standard.set(newValue, forKey: languageKey) }
    }

    static var lastSoundID: String? {
        get { UserDefaults.standard.string(forKey: lastSoundKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastSoundKey) }
    }

    static var lastTimerMinutes: Int? {
        get {
            guard UserDefaults.standard.object(forKey: lastTimerKey) != nil else { return nil }
            return UserDefaults.standard.integer(forKey: lastTimerKey)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: lastTimerKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastTimerKey)
            }
        }
    }

    static func markOnboardingCompleted() {
        onboardingCompleted = true
    }

    static func sync(from prefs: UserPreferences) {
        if prefs.onboardingCompleted { onboardingCompleted = true }
        if prefs.didRequestLocationPermission || prefs.didRequestMotionPermission || prefs.didRequestNotificationPermission {
            permissionsRequested = true
        }
        selectedLanguage = prefs.selectedLanguage
        lastSoundID = prefs.lastSoundID
        lastTimerMinutes = prefs.lastTimerMinutes
    }

    static func apply(to prefs: UserPreferences) {
        if onboardingCompleted { prefs.onboardingCompleted = true }
        if permissionsRequested {
            prefs.didRequestLocationPermission = true
            prefs.didRequestMotionPermission = true
            prefs.didRequestNotificationPermission = true
        }
        if let selectedLanguage { prefs.selectedLanguage = selectedLanguage }
        if let lastSoundID { prefs.lastSoundID = lastSoundID }
        if let lastTimerMinutes { prefs.lastTimerMinutes = lastTimerMinutes }
    }
}


import HealthKit

/// Apple Health (HealthKit) entegrasyonu:
/// Tamamlanan dinlenme ve odaklanma seanslarını Apple Sağlık uygulamasına
/// 'Farkındalık Dakikası' (Mindful Minutes) olarak işler.
@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private let mindfulType = HKCategoryType(.mindfulSession)
    private var isAuthorized = false

    private init() {}

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await healthStore.requestAuthorization(toShare: [mindfulType], read: [mindfulType])
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    func saveMindfulSession(startDate: Date, endDate: Date) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let duration = endDate.timeIntervalSince(startDate)
        // 60 saniyeden kısa denemeleri kaydetme
        guard duration >= 60 else { return }

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate,
            metadata: [
                HKMetadataKeyWasUserEntered: false,
                "StillwaySession": true
            ]
        )

        Task {
            do {
                if !isAuthorized {
                    await requestAuthorization()
                }
                try await healthStore.save(sample)
            } catch {
                // Hata durumunda sessizce devam et
            }
        }
    }
}
