import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class PurchaseManager {
    static let proProductID = "com.sinannergiz.stillway.pro"

    var isPro = true
    var isLoading = false
    var proProduct: Product?
    var product: Product? { proProduct }
    var errorMessage: String?
    var lastError: String? { errorMessage }

    init() {
        if StillwayTesting.unlockAllFeatures {
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
            isPro = UserDefaults.standard.bool(forKey: "stillway.isPro.debug")
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
    }
}
