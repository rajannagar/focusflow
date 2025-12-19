import Foundation
import Combine
import StoreKit
import UIKit

/// Central place to know if the user has Pro, load products, purchase, and restore.
@MainActor
final class ProEntitlementManager: ObservableObject {

    static let monthlyID = "com.softcomputers.focusflow.pro.monthly"
    static let yearlyID  = "com.softcomputers.focusflow.pro.yearly"

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Keep entitlement updated if purchases happen / renewals happen.
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await _ in Transaction.updates {
                await self.refreshEntitlement()
            }
        }

        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        lastErrorMessage = nil
        do {
            let ids = [Self.monthlyID, Self.yearlyID]
            let loaded = try await Product.products(for: ids)

            // Sort yearly first then monthly
            self.products = loaded.sorted {
                if $0.id == Self.yearlyID { return true }
                if $1.id == Self.yearlyID { return false }
                return $0.id < $1.id
            }
        } catch {
            lastErrorMessage = "Failed to load products. Check StoreKit config / Sandbox login."
        }
    }

    func refreshEntitlement() async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productType == .autoRenewable,
               (transaction.productID == Self.monthlyID || transaction.productID == Self.yearlyID),
               transaction.revocationDate == nil {
                hasPro = true
                break
            }
        }

        self.isPro = hasPro
    }

    func purchase(_ product: Product) async {
        lastErrorMessage = nil
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastErrorMessage = "Purchase could not be verified."
                    return
                }
                await transaction.finish()
                await refreshEntitlement()

            case .userCancelled:
                break
            case .pending:
                lastErrorMessage = "Purchase pending. Please complete on your Apple ID."
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        lastErrorMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch {
            lastErrorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func openManageSubscriptions() async {
        do {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    _ = await UIApplication.shared.open(url)
                }
                return
            }

            try await AppStore.showManageSubscriptions(in: scene)
        } catch {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                _ = await UIApplication.shared.open(url)
            }
        }
    }
}

