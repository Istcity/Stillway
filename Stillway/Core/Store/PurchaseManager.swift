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
