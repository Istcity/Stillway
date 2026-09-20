import SwiftUI
import SwiftData

struct ContentRootView: View {
    @Environment(ContextEngine.self) private var runtime
    @Environment(ThemeEngine.self) private var theme
    @Environment(PurchaseManager.self) private var store
    @Environment(\.lm) private var lm
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Query private var prefs: [UserPreferences]

    @State private var forceShowPaywall = false

    private var hasCompletedOnboarding: Bool {
        StillwayMemory.onboardingCompleted || prefs.first?.onboardingCompleted == true
    }

    private var isProUser: Bool {
        true // Paid App upfront model: user purchased on App Store before download
    }

    var body: some View {
        ZStack {
            if CommandLine.arguments.contains("-forcePaywall") || forceShowPaywall {
                ProPaywallView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else if isProUser {
                MainView()
                    .transition(.opacity)
            } else {
                ProPaywallView()
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.8), value: hasCompletedOnboarding)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.8), value: isProUser)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.8), value: forceShowPaywall)
        .sheet(isPresented: Bindable(runtime).showPlaceLabel) {
            PlaceLabelSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onAppear {
            reconcileOnboardingFlag()
            consumePendingToggle()
            if !StillwayMemory.permissionsRequested {
                Task {
                    await runtime.requestStartupPermissions()
                }
            }
        }
    }

    private func reconcileOnboardingFlag() {
        if StillwayMemory.onboardingCompleted, let prefs = prefs.first, !prefs.onboardingCompleted {
            prefs.onboardingCompleted = true
            try? modelContext.save()
        }
        if let prefs = prefs.first, prefs.onboardingCompleted {
            StillwayMemory.markOnboardingCompleted()
            StillwayMemory.sync(from: prefs)
        }
    }

    private func handleDeepLink(_ url: URL) {
        switch url.host {
        case "toggle":
            runtime.handleStartStop(preferences: prefs.first)
        case "sounds":
            forceShowPaywall = false
            runtime.showSounds = true
        case "places":
            forceShowPaywall = false
            runtime.showPlaces = true
        case "settings":
            forceShowPaywall = false
            runtime.showSettings = true
        case "paywall":
            runtime.showSounds = false
            runtime.showPlaces = false
            runtime.showSettings = false
            forceShowPaywall = true
        case "demo":
            handleDemoDeepLink(url)
        case "context":
            forceShowPaywall = false
            if let raw = url.pathComponents.dropFirst().first, let ctx = AppContext.allCases.first(where: { "\($0)".lowercased() == raw.lowercased() }) {
                theme.apply(context: ctx)
                if let s = Sound.sounds(for: ctx).first {
                    runtime.selectSound(s, isPro: true, preferences: prefs.first)
                }
            }
        case "sound":
            forceShowPaywall = false
            if let soundId = url.pathComponents.dropFirst().first, let s = Sound.library.first(where: { $0.id == soundId }) {
                theme.apply(soundID: s.id, context: s.context)
                runtime.selectSound(s, isPro: true, preferences: prefs.first)
            }
        default:
            break
        }
    }

    private func handleDemoDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let queryItems = components.queryItems ?? []
        let getParam: (String) -> String? = { key in
            queryItems.first(where: { $0.name == key })?.value
        }

        // 1. Language switch
        if let langStr = getParam("lang"), let code = LanguageCode(rawValue: langStr) {
            lm.currentLanguage = code
            StillwayMemory.selectedLanguage = code.rawValue
            prefs.first?.selectedLanguage = code.rawValue
        }

        // 2. Context switch
        if let ctxStr = getParam("context"),
           let ctx = AppContext.allCases.first(where: { "\($0)".lowercased() == ctxStr.lowercased() }) {
            theme.apply(context: ctx)
        }

        // 3. Sound selection
        if let sndStr = getParam("sound"), let snd = Sound.find(sndStr) {
            theme.apply(soundID: snd.id, context: snd.context)
            runtime.selectSound(snd, isPro: true, preferences: prefs.first)
        }

        // 4. Secondary sound for sound mixer
        if let secStr = getParam("secondary"), let secSnd = Sound.find(secStr) {
            runtime.audio.playSecondary(sound: secSnd)
            runtime.audio.secondaryVolume = 0.75
        } else if getParam("clearSecondary") == "true" {
            runtime.audio.stopSecondary()
        }

        // 5. Seed places if requested
        if getParam("seedPlaces") == "true" {
            seedDemoPlaces()
        }

        // 6. Navigation
        let view = getParam("view") ?? "main"
        runtime.showSounds = false
        runtime.showPlaces = false
        runtime.showSettings = false
        forceShowPaywall = false

        switch view {
        case "sounds":
            runtime.showSounds = true
        case "places":
            runtime.showPlaces = true
        case "settings":
            runtime.showSettings = true
        case "paywall":
            forceShowPaywall = true
        default:
            break
        }
    }

    private func seedDemoPlaces() {
        let existing = (try? modelContext.fetch(FetchDescriptor<UserPlace>())) ?? []
        guard existing.isEmpty else { return }

        let isJa = lm.currentLanguage == .ja
        let isTr = lm.currentLanguage == .tr

        let p1 = UserPlace(
            latitude: 35.6812,
            longitude: 139.7671,
            radius: 120,
            label: .work,
            visitCount: 38,
            autoStartEnabled: true,
            homeConfidence: 0.96,
            customName: isJa ? "東京駅 • 丸の内" : (isTr ? "Tokyo Merkez Garı" : "Tokyo Central Station")
        )
        let p2 = UserPlace(
            latitude: 35.6595,
            longitude: 139.7005,
            radius: 90,
            label: .cafe,
            visitCount: 21,
            autoStartEnabled: true,
            homeConfidence: 0.88,
            customName: isJa ? "渋谷スクランブル" : (isTr ? "Shibuya Odak Noktası" : "Shibuya Crossing")
        )
        let p3 = UserPlace(
            latitude: 35.6762,
            longitude: 139.6503,
            radius: 150,
            label: .home,
            visitCount: 64,
            autoStartEnabled: true,
            homeConfidence: 0.99,
            customName: isJa ? "自宅の聖域" : (isTr ? "Ev Sığınağı" : "Home Sanctuary")
        )
        modelContext.insert(p1)
        modelContext.insert(p2)
        modelContext.insert(p3)
        try? modelContext.save()
    }

    private func consumePendingToggle() {
        let defaults = UserDefaults(suiteName: "group.com.sinannergiz.stillway")
        guard defaults?.bool(forKey: "pendingToggle") == true else { return }
        defaults?.set(false, forKey: "pendingToggle")
        runtime.handleStartStop(preferences: prefs.first)
    }
}
