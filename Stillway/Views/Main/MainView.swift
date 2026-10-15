import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(ContextEngine.self) private var runtime
    @Environment(ThemeEngine.self) private var theme
    @Environment(\.lm) private var lm
    @Environment(\.modelContext) private var modelContext
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Query private var preferences: [UserPreferences]

    private enum MainSheet: Int, Identifiable {
        case settings = 1
        case sounds = 2
        case places = 3
        case paywall = 4

        var id: Int { rawValue }
    }

    @State private var activeSheet: MainSheet? = nil
    @State private var showControls = true
    @State private var isOLEDMode = false

    private enum ClockStyle: String {
        case dial
        case tube
    }

    @State private var clockStyle: ClockStyle = .dial
    @State private var showTimerPicker = false

    private func toggleControls() {
        HapticEngine.tap()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showControls.toggle()
        }
    }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var activeSound: Sound {
        runtime.audio.primarySound ?? Sound.sounds(for: theme.currentContext).first ?? Sound.library.first!
    }

    private var availableSounds: [Sound] {
        Sound.library
    }

    private var isUserPro: Bool {
        preferences.first?.isPro == true || StillwayTesting.unlockAllFeatures
    }

    var body: some View {
        ZStack {
            // Generative 3D volumetric atmosphere backdrop (expands across full screen)
            AtmosphereView()
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleControls()
                }

            // OLED Gece Masası / Pil Tasarrufu Modu (Saf #000000 derin siyah)
            if isOLEDMode {
                Color.black
                    .opacity(0.94)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleControls()
                    }
            }

            // Subtle vignette for cinematic depth
            RadialGradient(
                colors: [.clear, .black.opacity(0.22)],
                center: .center,
                startRadius: isLandscape ? 120 : 90,
                endRadius: isLandscape ? 680 : 580
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }

            // Auto-start banner
            if runtime.showAutoBanner && !isLandscape {
                AutoStartBanner(text: lm.string("auto_banner"))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 48)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .contextThemed()
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .sounds:
                SoundPickerSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .places:
                PlacesSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .paywall:
                ProPaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            ensurePreferences()
            if preferences.first?.didRequestLocationPermission != true {
                Task { await runtime.requestStartupPermissions() }
            }
        }
        .onChange(of: runtime.showSettings) { _, newValue in
            if newValue {
                activeSheet = .settings
                runtime.showSettings = false
            }
        }
        .onChange(of: runtime.showSounds) { _, newValue in
            if newValue {
                activeSheet = .sounds
                runtime.showSounds = false
            }
        }
        .onChange(of: runtime.showPlaces) { _, newValue in
            if newValue {
                activeSheet = .places
                runtime.showPlaces = false
            }
        }
        .onChange(of: runtime.showPaywall) { _, newValue in
            if newValue {
                activeSheet = .paywall
                runtime.showPaywall = false
            }
        }
    }

    // MARK: - Landscape Panoramic Studio Layout (Minimalist Ambient Clock)
    // All icons hidden, clock at far right, tapping toggles playback

    private var landscapeLayout: some View {
        ZStack {
            // Main Landscape Typography & Far-Right Living Timer
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(activeSound.localizedTitle(using: lm))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: theme.gradient.accentColor.opacity(0.55), radius: 14)

                    Text(activeSound.localizedSubtitle(using: lm))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                        .frame(maxWidth: 380, alignment: .leading)

                    if !runtime.audio.isPlaying {
                        Text(lm.string("toast_stopped"))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial.opacity(0.55), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))
                            .padding(.top, 8)
                    }
                }
                .padding(.leading, 48)

                Spacer(minLength: 40)

                // Far Right: Living Timer Tube Clock
                VStack {
                    Spacer()
                    VerticalTimerTube(
                        progress: ringProgress,
                        remainingSeconds: runtime.audio.isPlaying ? runtime.audio.remainingSeconds : (runtime.selectedTimerMinutes ?? 30) * 60,
                        isPlaying: runtime.audio.isPlaying,
                        context: activeSound.context,
                        hideTopIcon: !showControls
                    ) { minutes in
                        runtime.selectTimer(minutes)
                    }
                    Spacer()
                }
                .padding(.trailing, 48)
            }

            // Controls overlay (Ekrana dokunulduğunda tüm ikonlar gelir)
            if showControls {
                VStack {
                    // Top Bar in Landscape
                    topBar
                        .padding(.horizontal, 36)
                        .padding(.top, 14)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    Spacer()

                    // In-app volume bar in landscape
                    volumeBar
                        .scaleEffect(0.90)
                        .padding(.bottom, 2)
                        .transition(.opacity)

                    // Bottom diversified horizontal carousel in landscape
                    SoundCarouselView(
                        sounds: availableSounds,
                        selectedSound: activeSound,
                        isPlaying: runtime.audio.isPlaying,
                        isPro: isUserPro,
                        onSelectSound: { sound in
                            selectSound(sound)
                        },
                        onTogglePlay: {
                            runtime.handleStartStop(preferences: preferences.first)
                        }
                    )
                    .scaleEffect(0.90)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Top control navigation bar (ekrana dokunulduğunda gelir/gider)
            if showControls {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                Spacer(minLength: 12)

                // Interactive Context Dropdown Capsule
                contextDropdownPill
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                Spacer().frame(height: 52)
            }

            Spacer(minLength: 10)

            // Dynamic Sound Title & Poetic Subtitle (Strictly NO underline)
            VStack(spacing: 6) {
                Text(activeSound.localizedTitle(using: lm))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: theme.gradient.accentColor.opacity(0.4), radius: 10)
                    .contentTransition(.opacity)

                Text(activeSound.localizedSubtitle(using: lm))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .contentTransition(.opacity)
            }
            .animation(.easeInOut(duration: 0.3), value: activeSound.id)
            .padding(.top, 2)

            Spacer(minLength: 20)

            // Center area: Full-width Glowing Atmospheric Horizon + Centerpiece Living Clock
            ZStack(alignment: .center) {
                // Breathing luminous horizon beam across the entire screen width
                WaveformView()
                    .frame(height: 54)
                    .opacity(runtime.audio.isPlaying ? 0.85 : 0.45)
                    .allowsHitTesting(false)

                VStack(spacing: 12) {
                    if clockStyle == .dial {
                        zenDialCenterpiece
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    } else {
                        verticalTubeCenterpiece
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    }

                    if showTimerPicker {
                        durationPresetsPill
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
            }

            Spacer(minLength: 20)

            // "Durdu" / "Paused" indicator badge when audio is paused
            if !runtime.audio.isPlaying {
                Text(lm.string("toast_stopped"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.55), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 8)
            }

            // Bottom diversified horizontal carousel (ekrana dokunulduğunda gelir/gider)
            if showControls {
                volumeBar
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

                SoundCarouselView(
                    sounds: availableSounds,
                    selectedSound: activeSound,
                    isPlaying: runtime.audio.isPlaying,
                    isPro: isUserPro,
                    onSelectSound: { sound in
                        selectSound(sound)
                    },
                    onTogglePlay: {
                        runtime.handleStartStop(preferences: preferences.first)
                    }
                )
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Spacer().frame(height: 72)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaPadding(.bottom, 4)
    }

    // MARK: - Top Control Bar (Portrait)

    private var topBar: some View {
        HStack(spacing: 8) {
            // Settings button (Left circular)
            circleButton(systemName: "gearshape.fill", label: lm.string("settings_title")) {
                activeSheet = .settings
            }

            // Dynamic Live Forecast & City capsule (3 saat içinde beklenen durum)
            HStack(spacing: 6) {
                Image(systemName: runtime.weatherSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.yellow)
                Text(runtime.cityName.isEmpty ? "\(runtime.localizedWeatherSummary(using: lm)) • \(runtime.localizedWeatherCondition(using: lm))" : "\(runtime.cityName) • \(runtime.localizedWeatherSummary(using: lm))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.yellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.40), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.gradient.accentColor.opacity(0.70),
                                Color.white.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: theme.gradient.accentColor.opacity(0.25), radius: 8)

            // OLED Bedside Sleep Button
            circleButton(systemName: isOLEDMode ? "moon.stars.fill" : "moon.fill", label: "OLED") {
                HapticEngine.tap()
                withAnimation(.easeInOut(duration: 0.35)) {
                    isOLEDMode.toggle()
                }
            }

            if isLandscape {
                contextDropdownPill
            }

            Spacer()

            // Headphones button (opens sound library & frequency sheet)
            circleButton(systemName: "headphones", label: lm.string("sounds_title")) {
                activeSheet = .sounds
            }

            // Places / Compass button (Right circular)
            circleButton(systemName: "location.north.fill", label: lm.string("places_title")) {
                activeSheet = .places
            }
        }
    }

    // MARK: - Top Control Bar (Landscape)

    private var topBarLandscape: some View {
        HStack(spacing: 8) {
            circleButton(systemName: "gearshape.fill", label: lm.string("settings_title")) {
                activeSheet = .settings
            }

            HStack(spacing: 5) {
                Image(systemName: runtime.weatherSymbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.yellow)
                Text(runtime.weatherTemp)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.40), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.gradient.accentColor.opacity(0.70),
                                Color.white.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            circleButton(systemName: "headphones", label: lm.string("sounds_title")) {
                activeSheet = .sounds
            }

            circleButton(systemName: "location.north.fill", label: lm.string("places_title")) {
                activeSheet = .places
            }
        }
    }

    private func circleButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial.opacity(0.40), in: Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(label)
    }

    // MARK: - Centerpiece Clock & Visual Metaphor Engine

    private var zenDialCenterpiece: some View {
        Button {
            HapticEngine.medium()
            runtime.handleStartStop(preferences: preferences.first)
        } label: {
            ZStack {
                // Ambient Radial Pulse
                Circle()
                    .fill(theme.gradient.glowColor.opacity(runtime.audio.isPlaying ? 0.28 : 0.08))
                    .frame(width: 210, height: 210)
                    .blur(radius: 24)

                // Outer Frosted Glass Ring with Specular Rim
                Circle()
                    .fill(Color.black.opacity(0.38))
                    .frame(width: 190, height: 190)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.38),
                                        theme.gradient.accentColor.opacity(0.40),
                                        Color.white.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: theme.gradient.accentColor.opacity(runtime.audio.isPlaying ? 0.35 : 0.12), radius: 20)

                // Living Procedural Timer Face (Hourglass, Waterdrop, Sundial, Moon, etc.)
                TimerFaceView(
                    kind: TimerFaceKind.resolve(context: activeSound.context),
                    progress: ringProgress,
                    seconds: runtime.audio.isPlaying ? runtime.audio.remainingSeconds : (runtime.selectedTimerMinutes ?? 30) * 60
                )
                .scaleEffect(0.96)

                // Bottom Miniature Style Switch & Preset Button
                VStack {
                    Spacer()
                    Button {
                        HapticEngine.tap()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showTimerPicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10, weight: .bold))
                            Text(displayTimerTitle)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                            Image(systemName: showTimerPicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial.opacity(0.70), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                    .offset(y: 18)
                }
                .frame(width: 190, height: 190)
            }
        }
        .buttonStyle(.plain)
    }

    private var verticalTubeCenterpiece: some View {
        VStack(spacing: 8) {
            VerticalTimerTube(
                progress: ringProgress,
                remainingSeconds: runtime.audio.isPlaying ? runtime.audio.remainingSeconds : (runtime.selectedTimerMinutes ?? 30) * 60,
                isPlaying: runtime.audio.isPlaying,
                context: activeSound.context,
                hideTopIcon: false
            ) { minutes in
                runtime.selectTimer(minutes)
            }
            .frame(height: 200)

            Button {
                HapticEngine.tap()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    showTimerPicker.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 10, weight: .bold))
                    Text(displayTimerTitle)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Image(systemName: showTimerPicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial.opacity(0.70), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private var durationPresetsPill: some View {
        HStack(spacing: 8) {
            // Style toggle button (Dial vs Tube)
            Button {
                HapticEngine.tap()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    clockStyle = (clockStyle == .dial) ? .tube : .dial
                }
            } label: {
                Image(systemName: clockStyle == .dial ? "gauge.with.needle" : "hourglass.bottomhalf.filled")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.gradient.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 18)
                .overlay(Color.white.opacity(0.25))

            // Presets: 15, 30, 45, 60, ∞
            ForEach([15, 30, 45, 60], id: \.self) { mins in
                presetButton(title: "\(mins)\(lm.string("timer_min"))", minutes: mins)
            }
            presetButton(title: "∞", minutes: nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.65), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
    }

    private func presetButton(title: String, minutes: Int?) -> some View {
        let isSelected = runtime.selectedTimerMinutes == minutes
        return Button {
            HapticEngine.select()
            runtime.selectTimer(minutes)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.70))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isSelected ? theme.gradient.accentColor.opacity(0.85) : Color.white.opacity(0.06),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private var displayTimerTitle: String {
        if let mins = runtime.selectedTimerMinutes {
            return "\(mins) \(lm.string("timer_min"))"
        } else {
            return "∞"
        }
    }

    // MARK: - Context Dropdown Capsule (Matching Screenshots)

    private var contextDropdownPill: some View {
        Menu {
            Button(lm.string("ctx_commute").uppercased(), systemImage: "tram.fill") { switchContext(.commute) }
            Button(lm.string("ctx_focus").uppercased(), systemImage: "brain.head.profile") { switchContext(.focus) }
            Button(lm.string("ctx_reset").uppercased(), systemImage: "leaf.fill") { switchContext(.reset) }
            Button(lm.string("ctx_sleep").uppercased(), systemImage: "moon.fill") { switchContext(.sleep) }
            Button(lm.string("ctx_walking").uppercased(), systemImage: "figure.walk") { switchContext(.walking) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: contextIconName)
                    .font(.system(size: 13, weight: .bold))
                Text(contextDisplayName.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.4)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(theme.gradient.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(theme.gradient.accentColor.opacity(0.18), in: Capsule())
            .overlay(Capsule().stroke(theme.gradient.accentColor.opacity(0.45), lineWidth: 1))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: theme.currentContext)
    }

    private var contextDisplayName: String {
        switch theme.currentContext {
        case .commute: return lm.string("ctx_commute")
        case .focus, .deepWork: return lm.string("ctx_focus")
        case .reset: return lm.string("ctx_reset")
        case .sleep: return lm.string("ctx_sleep")
        case .walking: return lm.string("ctx_walking")
        case .unknown: return lm.string("ctx_focus")
        }
    }

    private var contextIconName: String {
        switch theme.currentContext {
        case .commute: return "tram.fill"
        case .focus, .deepWork: return "brain.head.profile"
        case .reset: return "leaf.fill"
        case .sleep: return "moon.fill"
        case .walking: return "figure.walk"
        case .unknown: return "sparkles"
        }
    }

    private func switchContext(_ ctx: AppContext) {
        HapticEngine.select()
        theme.apply(context: ctx)
        if let firstSound = Sound.sounds(for: ctx).first {
            selectSound(firstSound)
        }
    }

    private func selectSound(_ sound: Sound) {
        if !sound.isFree && !isUserPro {
            HapticEngine.tap()
            activeSheet = .paywall
            return
        }
        theme.apply(soundID: sound.id, context: sound.context)
        runtime.selectSound(sound, isPro: isUserPro, preferences: preferences.first)
        if !runtime.audio.isPlaying {
            runtime.handleStartStop(preferences: preferences.first)
        }
    }

    private var ringProgress: Double {
        let total = Double((runtime.selectedTimerMinutes ?? 30) * 60)
        guard total > 0 else { return 0 }
        return 1.0 - Double(runtime.audio.remainingSeconds) / total
    }

    // MARK: - In-App Minimalist Volume Control Bar

    private var volumeBar: some View {
        HStack(spacing: 12) {
            Image(systemName: runtime.audio.primaryVolume < 0.05 ? "speaker.slash.fill" : (runtime.audio.primaryVolume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 18)

            Slider(
                value: Binding(
                    get: { Double(runtime.audio.primaryVolume) },
                    set: { newVal in
                        runtime.audio.primaryVolume = Float(newVal)
                    }
                ),
                in: 0.0...1.0
            )
            .tint(theme.gradient.accentColor)

            Text("\(Int(runtime.audio.primaryVolume * 100))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(maxWidth: 260)
        .background(.ultraThinMaterial.opacity(0.42), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
    }

    private func ensurePreferences() {
        if preferences.isEmpty {
            let p = UserPreferences()
            #if DEBUG
            p.isPro = true
            #endif
            modelContext.insert(p)
        } else if StillwayTesting.unlockAllFeatures, let first = preferences.first {
            first.isPro = true
        }
        runtime.prepareDefaultAtmosphereIfNeeded()
    }
}

private struct AutoStartBanner: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            PulsingDot()
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

}
