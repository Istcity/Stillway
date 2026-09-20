import SwiftUI
import SwiftData
import CoreLocation
import CoreMotion
import UserNotifications
import UIKit

/// Ultra-premium luxury settings sheet.
/// Designed without any underlined headers, dividers, or standard form rows.
/// Features floating frosted glass cards, subtle glowing icon badges,
/// instantaneous multilingual switching, and on-device privacy telemetry.
struct SettingsSheet: View {
    @Environment(ContextEngine.self) private var runtime
    @Environment(\.lm) private var lm
    @Environment(ThemeEngine.self) private var theme
    @Environment(PurchaseManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]

    @State private var permissionSnapshot: PermissionBootstrap.Snapshot?
    @State private var isRefreshingPermissions = false

    private var accent: Color { theme.gradient.accentColor }

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient backdrop
                Color(hex: 0x07090E).ignoresSafeArea()

                // Subtle radial glow matching active theme
                RadialGradient(
                    colors: [accent.opacity(0.18), Color.clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {

                        // Header Status Pill
                        headerBadge

                        // Section 1: Audio & Intelligence
                        sectionBlock(title: lm.string("settings_general")) {
                            glassCard {
                                VStack(spacing: 18) {
                                    toggleRow(
                                        icon: "sparkles",
                                        title: lm.string("settings_context"),
                                        subtitle: lm.string("settings_context_desc"),
                                        keyPath: \.contextDetectionEnabled
                                    )

                                    toggleRow(
                                        icon: "moon.stars.fill",
                                        title: lm.string("settings_sleep"),
                                        subtitle: lm.string("settings_sleep_desc"),
                                        keyPath: \.sleepModeEnabled
                                    )

                                    if prefs?.sleepModeEnabled == true {
                                        HStack(spacing: 12) {
                                            datePickerPill(title: lm.string("settings_sleep_start"), selection: sleepStartDate)
                                            datePickerPill(title: lm.string("settings_sleep_end"), selection: sleepEndDate)
                                        }
                                        .padding(.top, 4)
                                    }

                                    toggleRow(
                                        icon: "lungs.fill",
                                        title: lm.string("settings_haptic"),
                                        subtitle: lm.string("settings_haptic_desc"),
                                        keyPath: \.hapticBreathingEnabled
                                    )
                                    .disabled(!runtime.breathing.isSupported)
                                }
                            }
                        }

                        // Section 2: Language & Region
                        sectionBlock(title: lm.string("settings_language")) {
                            glassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack(spacing: 10) {
                                        iconSquircle("globe")
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(lm.string("settings_language"))
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                            Text(lm.string("settings_language_note"))
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white.opacity(0.55))
                                        }
                                    }

                                    // 4 Direct Language Switcher Pills
                                    HStack(spacing: 8) {
                                        ForEach(LanguageCode.allCases) { code in
                                            let isCurrent = lm.currentLanguage == code
                                            Button {
                                                HapticEngine.select()
                                                lm.currentLanguage = code
                                                prefs?.selectedLanguage = code.rawValue
                                            } label: {
                                                HStack(spacing: 5) {
                                                    Text(code.flag)
                                                        .font(.system(size: 14))
                                                    Text(code.displayName)
                                                        .font(.system(size: 12, weight: isCurrent ? .bold : .medium, design: .rounded))
                                                }
                                                .foregroundStyle(isCurrent ? .black : .white.opacity(0.85))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 9)
                                                .background(
                                                    Capsule()
                                                        .fill(isCurrent ? accent : Color.white.opacity(0.08))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(isCurrent ? Color.clear : Color.white.opacity(0.12), lineWidth: 0.8)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Section 3: Pro & Audio Engine
                        sectionBlock(title: lm.string("settings_pro_section")) {
                            proCard
                        }

                        // Section 4: System Permissions
                        sectionBlock(title: lm.string("settings_permissions")) {
                            glassCard {
                                VStack(spacing: 16) {
                                    permissionRow(
                                        icon: "location.fill",
                                        title: lm.string("settings_perm_location"),
                                        status: locationStatusText,
                                        needsSettings: locationNeedsSettings
                                    )

                                    permissionRow(
                                        icon: "figure.walk",
                                        title: lm.string("settings_perm_motion"),
                                        status: motionStatusText,
                                        needsSettings: motionNeedsSettings
                                    )

                                    permissionRow(
                                        icon: "bell.fill",
                                        title: lm.string("settings_perm_notifications"),
                                        status: notificationStatusText,
                                        needsSettings: notificationNeedsSettings
                                    )

                                    HStack(spacing: 12) {
                                        Button {
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url)
                                            }
                                        } label: {
                                            Text(lm.string("settings_open_settings"))
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(accent, in: Capsule())
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            Task {
                                                isRefreshingPermissions = true
                                                await runtime.requestStartupPermissions()
                                                await refreshPermissions()
                                                isRefreshingPermissions = false
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                if isRefreshingPermissions {
                                                    ProgressView()
                                                        .controlSize(.small)
                                                }
                                                Text(lm.string("settings_request_permissions"))
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                            }
                                            .foregroundStyle(.white.opacity(0.85))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.08), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }

                        // Section 5: Privacy & About
                        sectionBlock(title: lm.string("settings_about")) {
                            glassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 10) {
                                        iconSquircle("shield.lefthalf.filled")
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(lm.string("settings_privacy"))
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                .foregroundStyle(.white.opacity(0.45))
                                        }
                                        Spacer()
                                    }

                                    Text(lm.string("privacy_body"))
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.58))
                                        .lineSpacing(3)

                                    Text(lm.string("settings_engine_status"))
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(accent.opacity(0.8))
                                        .padding(.top, 4)
                                }
                            }
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(lm.string("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.string("btn_done")) {
                        HapticEngine.tap()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
        .onAppear {
            ensurePreferences()
            Task { await refreshPermissions() }
        }
        .onChange(of: store.isPro) { _, isPro in
            prefs?.isPro = isPro
        }
    }

    // MARK: - Header Badge

    private var headerBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .shadow(color: accent, radius: 4)

            Text("STILLWAY NEURAL AUDIO")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Text(lm.string("settings_audio_library"))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accent.opacity(0.14), in: Capsule())
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Pro Card

    private var proCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 14) {
                let isProActive = store.isPro || StillwayTesting.unlockAllFeatures

                HStack(spacing: 10) {
                    iconSquircle("sparkles")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isProActive ? lm.string("settings_pro_badge_unlocked") : "Stillway Pro")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(isProActive ? lm.string("pro_active_desc") : lm.string("pro_locked_desc"))
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    if isProActive {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(accent)
                    }
                }

                if !isProActive {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(1...6, id: \.self) { index in
                            HStack(spacing: 8) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 10))
                                    .foregroundStyle(accent)
                                Text(lm.string("settings_pro_feature_\(index)"))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.78))
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        Task { await store.purchase() }
                    } label: {
                        Text(lm.string("settings_pro_btn"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(accent, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await store.restorePurchases() }
                    } label: {
                        Text(lm.string("settings_restore"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12))
                        Text(lm.string("settings_engine_status"))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(accent.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Section Block (STRICTLY NO UNDERLINE)

    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.42))
                .padding(.leading, 6)

            content()
        }
    }

    // MARK: - Glass Card Container

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Setting Rows & Helpers

    private func iconSquircle(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(accent)
            .frame(width: 32, height: 32)
            .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func toggleRow(icon: String, title: String, subtitle: String, keyPath: ReferenceWritableKeyPath<UserPreferences, Bool>) -> some View {
        HStack(spacing: 12) {
            iconSquircle(icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
            }
            Spacer()
            Toggle("", isOn: bind(keyPath))
                .labelsHidden()
                .tint(accent)
        }
    }

    private func datePickerPill(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func permissionRow(icon: String, title: String, status: String, needsSettings: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            iconSquircle(icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(status)
                    .font(.system(size: 12))
                    .foregroundStyle(needsSettings ? Color.orange.opacity(0.9) : Color.white.opacity(0.48))
            }
            Spacer()
            Image(systemName: needsSettings ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(needsSettings ? Color.orange : Color.green.opacity(0.85))
        }
    }

    // MARK: - State & Model Bindings

    private var prefs: UserPreferences? { preferences.first }

    private var sleepStartDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: prefs?.sleepStartHour ?? 22, minute: 0, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                prefs?.sleepStartHour = Calendar.current.component(.hour, from: date)
            }
        )
    }

    private var sleepEndDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: prefs?.sleepEndHour ?? 7, minute: 0, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                prefs?.sleepEndHour = Calendar.current.component(.hour, from: date)
            }
        )
    }

    private var locationStatusText: String {
        switch permissionSnapshot?.locationStatus ?? runtime.location.authStatus {
        case .authorizedAlways: return lm.string("perm_status_always")
        case .authorizedWhenInUse: return lm.string("perm_status_when_in_use")
        case .denied, .restricted: return lm.string("perm_status_denied")
        case .notDetermined: return lm.string("perm_status_not_determined")
        @unknown default: return lm.string("perm_status_unknown")
        }
    }

    private var motionStatusText: String {
        switch permissionSnapshot?.motionStatus ?? CMMotionActivityManager.authorizationStatus() {
        case .authorized: return lm.string("perm_status_allowed")
        case .denied, .restricted: return lm.string("perm_status_denied")
        case .notDetermined: return lm.string("perm_status_not_determined")
        @unknown default: return lm.string("perm_status_unknown")
        }
    }

    private var notificationStatusText: String {
        if permissionSnapshot?.notificationsAuthorized == true {
            return lm.string("perm_status_allowed")
        }
        if prefs?.didRequestNotificationPermission == true {
            return lm.string("perm_status_denied")
        }
        return lm.string("perm_status_not_determined")
    }

    private var locationNeedsSettings: Bool {
        let status = permissionSnapshot?.locationStatus ?? runtime.location.authStatus
        return status == .denied || status == .restricted || status == .authorizedWhenInUse
    }

    private var motionNeedsSettings: Bool {
        let status = permissionSnapshot?.motionStatus ?? CMMotionActivityManager.authorizationStatus()
        return status == .denied || status == .restricted
    }

    private var notificationNeedsSettings: Bool {
        prefs?.didRequestNotificationPermission == true && permissionSnapshot?.notificationsAuthorized != true
    }

    private func ensurePreferences() {
        if preferences.isEmpty { modelContext.insert(UserPreferences()) }
        if store.isPro || StillwayTesting.unlockAllFeatures { prefs?.isPro = true }
    }

    private func refreshPermissions() async {
        let snap = await PermissionBootstrap.currentSnapshot()
        permissionSnapshot = snap
        prefs?.lastKnownLocationAuthRaw = Int(snap.locationStatus.rawValue)
        prefs?.lastKnownMotionAuthRaw = Int(snap.motionStatus.rawValue)
        prefs?.lastKnownNotificationAuthorized = snap.notificationsAuthorized
        try? modelContext.save()
    }

    private func bind(_ keyPath: ReferenceWritableKeyPath<UserPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { prefs?[keyPath: keyPath] ?? false },
            set: { prefs?[keyPath: keyPath] = $0 }
        )
    }
}
