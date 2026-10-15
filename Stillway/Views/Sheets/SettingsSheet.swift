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
    @Environment(\.openURL) private var openURL
    @Query private var preferences: [UserPreferences]

    @State private var permissionSnapshot: PermissionBootstrap.Snapshot?
    @State private var isRefreshingPermissions = false

    private var accent: Color { theme.gradient.accentColor }

    private var isProActive: Bool {
        store.isPro || StillwayTesting.unlockAllFeatures
    }

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

                        // Section 2: Atmosphere & Visual Themes (Atmosfer ve Görsel Temalar)
                        sectionBlock(title: lm.string("settings_atmosphere")) {
                            glassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack(spacing: 10) {
                                        iconSquircle("paintpalette.fill")
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(lm.string("settings_atmosphere_title"))
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                            Text(lm.string("settings_atmosphere_desc"))
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white.opacity(0.55))
                                        }
                                        Spacer()
                                        if theme.atmosphereOverride != nil {
                                            Button {
                                                HapticEngine.tap()
                                                theme.atmosphereOverride = nil
                                            } label: {
                                                Text(lm.string("atmo_reset_auto"))
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundStyle(accent)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(accent.opacity(0.14), in: Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            themeCard(
                                                title: lm.string("atmo_auto"),
                                                icon: "sparkles",
                                                isSelected: theme.atmosphereOverride == nil,
                                                isFree: true,
                                                isLocked: false,
                                                gradient: theme.gradient
                                            ) {
                                                theme.atmosphereOverride = nil
                                            }

                                            ForEach(AtmosphereKind.allCases, id: \.self) { kind in
                                                let isSelected = theme.atmosphereOverride == kind
                                                let isLocked = !isProActive && !kind.isFree
                                                themeCard(
                                                    title: kind.displayName(using: lm),
                                                    icon: kind.symbol,
                                                    isSelected: isSelected,
                                                    isFree: kind.isFree,
                                                    isLocked: isLocked,
                                                    gradient: ContextGradient.gradient(for: kind)
                                                ) {
                                                    if isLocked {
                                                        HapticEngine.warning()
                                                        dismiss()
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                            runtime.showPaywall = true
                                                        }
                                                    } else {
                                                        theme.atmosphereOverride = kind
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 2)
                                    }
                                }
                            }
                        }

                        // Section 3: Language & Region
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
                                                runtime.localization = lm
                                                runtime.refreshWeatherLocalization()
                                                prefs?.selectedLanguage = code.rawValue
                                                try? modelContext.save()
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

                        // Section 5: Privacy Card & About (Gizlilik Kartı)
                        sectionBlock(title: lm.string("settings_privacy")) {
                            glassCard {
                                VStack(alignment: .leading, spacing: 14) {
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
                                        Text("100% OFFLINE")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.55))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(red: 0.4, green: 0.85, blue: 0.55).opacity(0.12), in: Capsule())
                                    }

                                    // Privacy Guarantees Pills
                                    HStack(spacing: 8) {
                                        privacyPill(icon: "cpu.fill", text: "On-Device")
                                        privacyPill(icon: "hand.raised.slash.fill", text: "Zero Tracking")
                                        privacyPill(icon: "person.slash.fill", text: "No Account")
                                    }

                                    Text(lm.string("privacy_body"))
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.68))
                                        .lineSpacing(3)

                                    // Action buttons: Privacy Policy, Terms, Rate Stillway
                                    VStack(spacing: 4) {
                                        Button {
                                            HapticEngine.tap()
                                            if let url = URL(string: "https://istcity.github.io/Stillway/privacy.html") {
                                                openURL(url)
                                            }
                                        } label: {
                                            HStack {
                                                Label(lm.string("paywall_privacy"), systemImage: "hand.raised.fill")
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                                Spacer()
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.white.opacity(0.4))
                                            }
                                            .foregroundStyle(.white.opacity(0.85))
                                            .padding(.vertical, 7)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            HapticEngine.tap()
                                            if let url = URL(string: "https://istcity.github.io/Stillway/terms.html") {
                                                openURL(url)
                                            }
                                        } label: {
                                            HStack {
                                                Label(lm.string("paywall_terms"), systemImage: "doc.text.fill")
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                                Spacer()
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.white.opacity(0.4))
                                            }
                                            .foregroundStyle(.white.opacity(0.85))
                                            .padding(.vertical, 7)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            HapticEngine.tap()
                                            StillwayReviewPrompter.openAppStoreReview()
                                        } label: {
                                            HStack {
                                                Label(rateAppTitle, systemImage: "star.fill")
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                                Spacer()
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.white.opacity(0.4))
                                            }
                                            .foregroundStyle(Color(red: 0.95, green: 0.8, blue: 0.45))
                                            .padding(.vertical, 7)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Text(lm.string("settings_engine_status"))
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(accent.opacity(0.8))
                                        .padding(.top, 2)
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
                        HapticEngine.tap()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            runtime.showPaywall = true
                        }
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

    private func themeCard(
        title: String,
        icon: String,
        isSelected: Bool,
        isFree: Bool,
        isLocked: Bool,
        gradient: ContextGradient,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticEngine.select()
            action()
        } label: {
            ZStack(alignment: .topTrailing) {
                // Card Background: Rich themed gradient
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                gradient.bgColors.first ?? Color(hex: 0x0A0F1E),
                                gradient.cardTint,
                                Color(hex: 0x05070B)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Atmospheric Radial Glow
                RadialGradient(
                    colors: [gradient.accentColor.opacity(isSelected ? 0.45 : 0.20), .clear],
                    center: .center,
                    startRadius: 5,
                    endRadius: 80
                )
                .allowsHitTesting(false)

                // Inner content
                VStack(alignment: .leading, spacing: 0) {
                    // Top Icon Squircle
                    ZStack {
                        Circle()
                            .fill(gradient.accentColor.opacity(0.18))
                            .frame(width: 38, height: 38)
                        Image(systemName: isLocked ? "lock.fill" : icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isLocked ? Color.white.opacity(0.65) : gradient.accentColor)
                    }
                    .padding(.top, 14)
                    .padding(.leading, 14)

                    Spacer()

                    // Bottom Titles & Info
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(gradient.accentColor)
                                .frame(width: 5, height: 5)
                            Text(statusText(isFree: isFree, isLocked: isLocked))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(isFree ? Color.green : (isLocked ? Color(red: 0.98, green: 0.82, blue: 0.45) : Color.white.opacity(0.7)))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }

                // Top Status Badge (Active or PRO)
                if isSelected {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                        Text(activeBadgeText)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(gradient.accentColor, in: Capsule())
                    .padding(10)
                } else if isLocked {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.45))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.98, green: 0.82, blue: 0.45).opacity(0.18), in: Capsule())
                    .overlay(Capsule().stroke(Color(red: 0.98, green: 0.82, blue: 0.45).opacity(0.4), lineWidth: 0.8))
                    .padding(10)
                }
            }
            .frame(width: 126, height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSelected ? AnyShapeStyle(gradient.accentColor) : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.white.opacity(0.24), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ),
                        lineWidth: isSelected ? 1.8 : 0.9
                    )
            )
            .shadow(color: isSelected ? gradient.accentColor.opacity(0.38) : Color.black.opacity(0.35), radius: isSelected ? 12 : 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func statusText(isFree: Bool, isLocked: Bool) -> String {
        if isFree {
            switch lm.currentLanguage {
            case .tr: return "ÜCRETSİZ"
            case .ja: return "無料"
            case .fr: return "GRATUIT"
            default: return "FREE"
            }
        } else if isLocked {
            return "PRO"
        } else {
            switch lm.currentLanguage {
            case .tr: return "AÇIK"
            case .ja: return "解除済"
            case .fr: return "DÉVERROUILLÉ"
            default: return "UNLOCKED"
            }
        }
    }

    private var activeBadgeText: String {
        switch lm.currentLanguage {
        case .tr: return "AKTİF"
        case .ja: return "有効"
        case .fr: return "ACTIF"
        default: return "ACTIVE"
        }
    }

    private func accentForKind(_ kind: AtmosphereKind) -> Color {
        switch kind {
        case .neonSmoke: return Color(hex: 0xFF007F)
        case .lavaTube: return Color(hex: 0xFF3D00)
        case .lightShow: return Color(hex: 0x00E5FF)
        case .aurora: return Color(hex: 0x7C4DFF)
        case .rain: return Color(hex: 0x00B0FF)
        case .lava: return Color(hex: 0xFF5722)
        case .stream: return Color(hex: 0x26C6DA)
        case .mist: return Color(hex: 0x2EE59D)
        case .ember: return Color(hex: 0xFFA726)
        case .snow: return Color(hex: 0x80D8FF)
        case .prism: return Color(hex: 0xE040FB)
        }
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

    private var rateAppTitle: String {
        switch lm.currentLanguage {
        case .tr: return "Stillway'i App Store'da Değerlendir"
        case .ja: return "App Storeで評価する"
        case .fr: return "Noter Stillway sur l'App Store"
        default: return "Rate Stillway on App Store"
        }
    }

    private func privacyPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}
