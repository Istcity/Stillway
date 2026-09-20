import SwiftUI
import SwiftData
import UIKit

struct OnboardingView: View {
    @Environment(ContextEngine.self) private var runtime
    @Environment(\.lm) private var lm
    @Environment(\.modelContext) private var modelContext
    @Query private var prefs: [UserPreferences]
    @State private var currentPage = 0
    @State private var didPrimePermissions = false

    var body: some View {
        TabView(selection: $currentPage) {
            OnboardPage1 { advanceFromFirst() }
                .tag(0)
            OnboardPage2(onContinue: { advanceFromSecond(openShortcuts: true) }, onSkip: { advanceFromSecond(openShortcuts: false) })
                .tag(1)
            OnboardPage3 { finish() }
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.95), value: currentPage)
        .onAppear {
            ensurePrefs()
            if StillwayMemory.onboardingCompleted {
                finish()
                return
            }
            primePermissionsIfNeeded()
        }
    }

    private func advanceFromFirst() {
        HapticEngine.tap()
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPage = 1
        }
        primePermissionsIfNeeded()
    }

    private func advanceFromSecond(openShortcuts: Bool) {
        HapticEngine.tap()
        if openShortcuts, let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
            prefs.first?.shortcutOnboardingDone = true
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPage = 2
        }
    }

    private func finish() {
        HapticEngine.success()
        ensurePrefs()
        prefs.first?.onboardingCompleted = true
        if let prefs = prefs.first {
            StillwayMemory.sync(from: prefs)
        }
        StillwayMemory.markOnboardingCompleted()
        try? modelContext.save()
        runtime.completeOnboarding()
    }

    private func ensurePrefs() {
        if prefs.isEmpty { modelContext.insert(UserPreferences()) }
    }

    private func primePermissionsIfNeeded() {
        guard !didPrimePermissions else { return }
        didPrimePermissions = true
        Task {
            await runtime.requestStartupPermissions()
        }
    }
}
