import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class PurchaseManager {
    static let proProductID = "com.sinannergiz.stillway.pro"

    var isPro = false
    var isLoading = false
    var proProduct: Product?
    var product: Product? { proProduct }
    var errorMessage: String?
    var lastError: String? { errorMessage }

    init() {
        if StillwayTesting.unlockAllFeatures || UserDefaults.standard.bool(forKey: "stillway.isPro.debug") {
            unlockForPreview()
        }
        Task { await loadProduct() }
        Task { await listenForTransactions() }
        Task { await refreshEntitlements() }
    }

    func load() async { await loadProduct() }

    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }
        do {
            proProduct = try await Product.products(for: [Self.proProductID]).first
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
            if StillwayTesting.unlockAllFeatures || UserDefaults.standard.bool(forKey: "stillway.isPro.debug") {
                isPro = true
            }
        }
    }

    func purchase() async {
        guard let proProduct else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await proProduct.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    isPro = true
                    errorMessage = nil
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlements()
        if isPro { errorMessage = nil }
    }

    func restore() async { await restorePurchases() }

    func unlockForPreview() {
        isPro = true
        UserDefaults.standard.set(true, forKey: "stillway.isPro.debug")
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update, transaction.productID == Self.proProductID {
                isPro = true
                await transaction.finish()
            }
        }
    }

    private func refreshEntitlements() async {
        if StillwayTesting.unlockAllFeatures || UserDefaults.standard.bool(forKey: "stillway.isPro.debug") {
            isPro = true
            return
        }
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement, transaction.productID == Self.proProductID {
                isPro = true
                return
            }
        }
        isPro = false
    }
}

import UIKit

// MARK: - App Store Review Request Controller
@MainActor
public enum StillwayReviewPrompter {
    private static let sessionCountKey = "stillway_completed_sessions_count"
    private static let lastReviewVersionKey = "stillway_last_reviewed_version"

    public static func recordCompletedSession() {
        let count = UserDefaults.standard.integer(forKey: sessionCountKey) + 1
        UserDefaults.standard.set(count, forKey: sessionCountKey)

        // Request review after 2nd and 5th completed session
        if count == 2 || count == 5 {
            requestReviewIfAppropriate()
        }
    }

    public static func requestReviewIfAppropriate() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let lastVersion = UserDefaults.standard.string(forKey: lastReviewVersionKey)

        guard currentVersion != lastVersion else { return }

        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(currentVersion, forKey: lastReviewVersionKey)
        }
    }

    public static func openAppStoreReview() {
        // Direct link to App Store product page review sheet
        if let url = URL(string: "https://apps.apple.com/app/id6670783307?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Smart Polite Paywall Prompter (Arada sırada, çok sıkmadan)
@MainActor
enum StillwayPaywallPrompter {
    private static let lastPromptTimestampKey = "stillway_last_paywall_prompt_timestamp"
    private static let sessionCountKey = "stillway_sessions_since_last_paywall_prompt"
    private static let totalCompletedSessionsKey = "stillway_completed_listening_sessions"

    /// Evaluates whether to gently show the soft paywall without annoying the user.
    static func evaluatePrompt(runtime: ContextEngine) {
        // Never prompt if already Pro or in test bypass mode
        let isPro = StillwayTesting.unlockAllFeatures || UserDefaults.standard.bool(forKey: "stillway.isPro.debug")
        guard !isPro else { return }

        let total = UserDefaults.standard.integer(forKey: totalCompletedSessionsKey) + 1
        UserDefaults.standard.set(total, forKey: totalCompletedSessionsKey)

        let sessionsSincePrompt = UserDefaults.standard.integer(forKey: sessionCountKey) + 1
        UserDefaults.standard.set(sessionsSincePrompt, forKey: sessionCountKey)

        // Rule 1: Never interrupt during the first 2 sessions (give user peace to enjoy free features)
        guard total >= 3 else { return }

        // Rule 2: Minimum 3 completed sessions between prompts
        guard sessionsSincePrompt >= 3 else { return }

        // Rule 3: Minimum 48 hours between prompts (çok sıkmadan)
        let lastPromptTime = UserDefaults.standard.double(forKey: lastPromptTimestampKey)
        let now = Date().timeIntervalSince1970
        let minInterval: Double = 48 * 3600 // 48 hours

        if lastPromptTime == 0 || (now - lastPromptTime) >= minInterval {
            UserDefaults.standard.set(now, forKey: lastPromptTimestampKey)
            UserDefaults.standard.set(0, forKey: sessionCountKey)

            // Show after gentle 1.2s delay so it feels natural, only if not playing and no sheets open
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if !runtime.audio.isPlaying && !runtime.showSettings && !runtime.showSounds {
                    runtime.showPaywall = true
                }
            }
        }
    }
}
