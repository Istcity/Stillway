import SwiftUI
import SwiftData

@main
struct StillwayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var contextEngine = ContextEngine()
    @State private var purchaseManager = PurchaseManager()
    @State private var lm = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environment(contextEngine)
                .environment(contextEngine.themeEngine)
                .environment(contextEngine.audioEngine)
                .environment(purchaseManager)
                .environment(\.lm, lm)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .onAppear {
                    contextEngine.localization = lm
                    contextEngine.configure(modelContext: sharedModelContainer.mainContext)
                    restorePreferences(into: sharedModelContainer.mainContext)
                    handleCommandLineArguments(into: sharedModelContainer.mainContext)
                    if StillwayTesting.unlockAllFeatures {
                        purchaseManager.unlockForPreview()
                        contextEngine.unlockAllFeaturesForTesting()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func restorePreferences(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<UserPreferences>())) ?? []
        let prefs: UserPreferences
        if let first = existing.first {
            prefs = first
        } else {
            prefs = UserPreferences()
            context.insert(prefs)
        }
        // Stillway upfront paid app model: ensure user has pro access
        prefs.isPro = true
        StillwayMemory.apply(to: prefs)
        if let language = StillwayMemory.selectedLanguage {
            lm.currentLanguage = LanguageCode(rawValue: language) ?? .en
        }
        try? context.save()
    }

    private func handleCommandLineArguments(into context: ModelContext) {
        let args = CommandLine.arguments
        let prefs = (try? context.fetch(FetchDescriptor<UserPreferences>()))?.first

        // Language
        if let idx = args.firstIndex(of: "-language"), idx + 1 < args.count {
            let lang = args[idx + 1]
            if let code = LanguageCode(rawValue: lang) {
                lm.currentLanguage = code
                StillwayMemory.selectedLanguage = code.rawValue
                prefs?.selectedLanguage = code.rawValue
                contextEngine.localization = lm
                contextEngine.refreshWeatherLocalization()
            }
        }

        // Mark onboarding completed for test/demo mode
        if args.contains("-bypassPaywall") || args.contains("-onboardingDone") {
            StillwayMemory.markOnboardingCompleted()
            prefs?.onboardingCompleted = true
        }

        // Context
        if let idx = args.firstIndex(of: "-context"), idx + 1 < args.count {
            let ctxStr = args[idx + 1]
            if let ctx = AppContext.allCases.first(where: { "\($0)".lowercased() == ctxStr.lowercased() }) {
                contextEngine.themeEngine.setImmediate(ctx)
            }
        }

        // Sound
        if let idx = args.firstIndex(of: "-sound"), idx + 1 < args.count {
            let soundID = args[idx + 1]
            if let s = Sound.find(soundID) {
                contextEngine.themeEngine.apply(soundID: s.id, context: s.context)
                contextEngine.selectSound(s, isPro: true, preferences: prefs)
            }
        }

        // Secondary sound
        if let idx = args.firstIndex(of: "-secondary"), idx + 1 < args.count {
            let secID = args[idx + 1]
            if let s = Sound.find(secID) {
                contextEngine.audio.playSecondary(sound: s)
                contextEngine.audio.secondaryVolume = 0.75
            }
        }

        // Screen navigation
        if let idx = args.firstIndex(of: "-screen"), idx + 1 < args.count {
            let screen = args[idx + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                switch screen {
                case "sounds":
                    contextEngine.showSounds = true
                case "places":
                    contextEngine.showPlaces = true
                case "settings":
                    contextEngine.showSettings = true
                default:
                    break
                }
            }
        }

        // Seed places
        if args.contains("-seedPlaces") {
            let existing = (try? context.fetch(FetchDescriptor<UserPlace>())) ?? []
            for p in existing {
                context.delete(p)
            }
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
                customName: isJa ? "渋谷スクランブル" : (isTr ? "Shibuya Odak Noktası" : "Shibuya Crossing Studio")
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
            context.insert(p1)
            context.insert(p2)
            context.insert(p3)
        }
        try? context.save()
    }
}

private let sharedModelContainer: ModelContainer = {
    let schema = Schema([UserPlace.self, CommuteSession.self, UserPreferences.self])
    let url = URL.applicationSupportDirectory.appending(path: "Stillway.store")

    do {
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(url: url)
        )
    } catch {
        // Schema changed — wipe incompatible store and recreate on disk (never prefer memory-only).
        try? FileManager.default.removeItem(at: url)
        for ext in ["store-shm", "store-wal"] {
            let side = url.deletingPathExtension().appendingPathExtension(ext)
            try? FileManager.default.removeItem(at: side)
        }
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(url: url)
            )
        } catch {
            assertionFailure("Stillway SwiftData failed twice: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }
}()
