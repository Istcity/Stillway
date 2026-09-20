import Foundation
import SwiftData
import CoreLocation

enum PlaceLabel: String, Codable, CaseIterable, Identifiable, Sendable {
    case unknown
    case home
    case work
    case library
    case cafe
    case gym
    case other

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .unknown: return "place_unknown"
        case .home: return "place_home"
        case .work: return "place_work"
        case .library: return "place_library"
        case .cafe: return "place_cafe"
        case .gym: return "place_gym"
        case .other: return "place_other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .unknown: return "mappin"
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .library: return "book.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .gym: return "figure.strengthtraining.traditional"
        case .other: return "star.fill"
        }
    }

    var symbolName: String { sfSymbol }

    var suggestedContext: AppContext {
        switch self {
        case .home: return .reset
        case .work, .library: return .focus
        case .cafe: return .focus
        case .gym: return .reset
        case .unknown, .other: return .unknown
        }
    }
}

@Model
final class UserPlace {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var radius: Double
    var labelRaw: String
    var visitCount: Int
    var firstSeen: Date
    var lastSeen: Date
    var defaultSoundID: String?
    var autoStartEnabled: Bool
    var homeConfidence: Double
    var customName: String?

    var label: PlaceLabel {
        get { PlaceLabel(rawValue: labelRaw) ?? .unknown }
        set { labelRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        radius: Double = 100,
        label: PlaceLabel = .unknown,
        visitCount: Int = 1,
        firstSeen: Date = .now,
        lastSeen: Date = .now,
        defaultSoundID: String? = nil,
        autoStartEnabled: Bool = false,
        homeConfidence: Double = 0,
        customName: String? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.labelRaw = label.rawValue
        self.visitCount = visitCount
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.defaultSoundID = defaultSoundID
        self.autoStartEnabled = autoStartEnabled
        self.homeConfidence = homeConfidence
        self.customName = customName
    }

    func distance(to location: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}

@Model
final class CommutSession {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var contextRaw: Int
    var soundID: String
    var fromStationID: String?
    var toStationID: String?
    var triggeredAutomatically: Bool
    var durationSeconds: Double

    var context: AppContext {
        get { AppContext(rawValue: contextRaw) ?? .unknown }
        set { contextRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        startDate: Date = .now,
        endDate: Date? = nil,
        context: AppContext,
        soundID: String,
        fromStationID: String? = nil,
        toStationID: String? = nil,
        triggeredAutomatically: Bool = false,
        durationSeconds: Double = 0
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.contextRaw = context.rawValue
        self.soundID = soundID
        self.fromStationID = fromStationID
        self.toStationID = toStationID
        self.triggeredAutomatically = triggeredAutomatically
        self.durationSeconds = durationSeconds
    }

    func end() {
        let finished = Date()
        endDate = finished
        durationSeconds = finished.timeIntervalSince(startDate)
    }
}

typealias CommuteSession = CommutSession

@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    var contextDetectionEnabled: Bool
    var sleepModeEnabled: Bool
    var sleepStartHour: Int
    var sleepEndHour: Int
    var hapticBreathingEnabled: Bool
    var shortcutOnboardingDone: Bool
    var isPro: Bool
    var onboardingCompleted: Bool
    var selectedLanguage: String
    var lastKnownLatitude: Double
    var lastKnownLongitude: Double
    var lastSoundID: String
    var lastTimerMinutes: Int

    /// Remember which system permission prompts were already shown.
    var didRequestLocationPermission: Bool
    var didRequestMotionPermission: Bool
    var didRequestNotificationPermission: Bool
    var locationPermissionRequestedAt: Date?
    var motionPermissionRequestedAt: Date?
    var notificationPermissionRequestedAt: Date?
    var lastKnownLocationAuthRaw: Int
    var lastKnownMotionAuthRaw: Int
    var lastKnownNotificationAuthorized: Bool

    var hasCompletedOnboarding: Bool {
        get { onboardingCompleted }
        set { onboardingCompleted = newValue }
    }

    init(
        id: UUID = UUID(),
        contextDetectionEnabled: Bool = true,
        sleepModeEnabled: Bool = true,
        sleepStartHour: Int = 22,
        sleepEndHour: Int = 7,
        hapticBreathingEnabled: Bool = false,
        shortcutOnboardingDone: Bool = false,
        isPro: Bool = true,
        onboardingCompleted: Bool = false,
        selectedLanguage: String = LanguageCode.detect().rawValue,
        lastKnownLatitude: Double = 0,
        lastKnownLongitude: Double = 0,
        lastSoundID: String = "tokyo_rain",
        lastTimerMinutes: Int = 30,
        didRequestLocationPermission: Bool = false,
        didRequestMotionPermission: Bool = false,
        didRequestNotificationPermission: Bool = false,
        locationPermissionRequestedAt: Date? = nil,
        motionPermissionRequestedAt: Date? = nil,
        notificationPermissionRequestedAt: Date? = nil,
        lastKnownLocationAuthRaw: Int = -1,
        lastKnownMotionAuthRaw: Int = -1,
        lastKnownNotificationAuthorized: Bool = false
    ) {
        self.id = id
        self.contextDetectionEnabled = contextDetectionEnabled
        self.sleepModeEnabled = sleepModeEnabled
        self.sleepStartHour = sleepStartHour
        self.sleepEndHour = sleepEndHour
        self.hapticBreathingEnabled = hapticBreathingEnabled
        self.shortcutOnboardingDone = shortcutOnboardingDone
        self.isPro = isPro
        self.onboardingCompleted = onboardingCompleted
        self.selectedLanguage = selectedLanguage
        self.lastKnownLatitude = lastKnownLatitude
        self.lastKnownLongitude = lastKnownLongitude
        self.lastSoundID = lastSoundID
        self.lastTimerMinutes = lastTimerMinutes
        self.didRequestLocationPermission = didRequestLocationPermission
        self.didRequestMotionPermission = didRequestMotionPermission
        self.didRequestNotificationPermission = didRequestNotificationPermission
        self.locationPermissionRequestedAt = locationPermissionRequestedAt
        self.motionPermissionRequestedAt = motionPermissionRequestedAt
        self.notificationPermissionRequestedAt = notificationPermissionRequestedAt
        self.lastKnownLocationAuthRaw = lastKnownLocationAuthRaw
        self.lastKnownMotionAuthRaw = lastKnownMotionAuthRaw
        self.lastKnownNotificationAuthorized = lastKnownNotificationAuthorized
    }
}
