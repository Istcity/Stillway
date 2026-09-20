import Foundation
import CoreLocation
import CoreMotion
import UserNotifications
import Observation

/// One-shot startup permission priming. Remembers what was asked in UserDefaults & UserPreferences.
@MainActor
enum PermissionBootstrap {
    struct Snapshot: Sendable {
        var locationStatus: CLAuthorizationStatus
        var motionStatus: CMAuthorizationStatus
        var notificationsAuthorized: Bool
    }

    static func currentSnapshot() async -> Snapshot {
        let notif = await UNUserNotificationCenter.current().notificationSettings()
        return Snapshot(
            locationStatus: CLLocationManager().authorizationStatus,
            motionStatus: CMMotionActivityManager.authorizationStatus(),
            notificationsAuthorized: notif.authorizationStatus == .authorized
                || notif.authorizationStatus == .provisional
        )
    }

    /// Request every permission Stillway needs upfront once and persist permanently into memory.
    static func requestAll(
        location: LocationManager,
        motion: MotionClassifier,
        preferences: UserPreferences?,
        save: () -> Void
    ) async {
        // If already requested at startup and recorded in memory, avoid re-prompting
        if StillwayMemory.permissionsRequested, preferences?.didRequestLocationPermission == true {
            motion.start()
            return
        }

        // Mark in memory immediately so repeated launches never trigger popups
        StillwayMemory.permissionsRequested = true

        guard let preferences else {
            location.requestWhenInUse()
            try? await Task.sleep(for: .milliseconds(400))
            location.requestAlwaysAuthorization()
            motion.start()
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return
        }

        if !preferences.didRequestLocationPermission {
            location.requestWhenInUse()
            try? await Task.sleep(for: .milliseconds(400))
            location.requestAlwaysAuthorization()
            preferences.didRequestLocationPermission = true
            preferences.locationPermissionRequestedAt = Date()
        } else if location.authStatus == .authorizedWhenInUse {
            location.requestAlwaysAuthorization()
        }

        if !preferences.didRequestMotionPermission {
            motion.start()
            preferences.didRequestMotionPermission = true
            preferences.motionPermissionRequestedAt = Date()
        } else {
            motion.start()
        }

        if !preferences.didRequestNotificationPermission {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            preferences.didRequestNotificationPermission = true
            preferences.notificationPermissionRequestedAt = Date()
        }

        let snap = await currentSnapshot()
        preferences.lastKnownLocationAuthRaw = Int(snap.locationStatus.rawValue)
        preferences.lastKnownMotionAuthRaw = Int(snap.motionStatus.rawValue)
        preferences.lastKnownNotificationAuthorized = snap.notificationsAuthorized
        save()
    }
}
