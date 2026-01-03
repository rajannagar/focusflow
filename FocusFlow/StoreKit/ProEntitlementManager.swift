import Foundation
import Combine
import StoreKit
import UIKit

/// Central place to know if the user has Pro, load products, purchase, and restore.
@MainActor
final class ProEntitlementManager: ObservableObject {

    static let monthlyID = "com.softcomputers.focusflow.pro.monthly"
    static let yearlyID  = "com.softcomputers.focusflow.pro.yearly"
    
    /// Shared singleton instance - use this everywhere to ensure single source of truth
    static let shared = ProEntitlementManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
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
        #if DEBUG
        print("[ProEntitlementManager] 🔄 Refreshing entitlement status...")
        #endif
        
        var hasPro = false
        var foundTransactions: [String] = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                #if DEBUG
                print("[ProEntitlementManager] ⚠️ Unverified transaction found")
                #endif
                continue
            }

            #if DEBUG
            print("[ProEntitlementManager] 📦 Found transaction: \(transaction.productID), type: \(transaction.productType.rawValue), revoked: \(transaction.revocationDate != nil)")
            #endif

            if transaction.productType == .autoRenewable,
               (transaction.productID == Self.monthlyID || transaction.productID == Self.yearlyID),
               transaction.revocationDate == nil {
                hasPro = true
                foundTransactions.append(transaction.productID)
                #if DEBUG
                print("[ProEntitlementManager] ✅ Valid Pro subscription found: \(transaction.productID)")
                #endif
                break
            }
        }

        let oldStatus = self.isPro
        self.isPro = hasPro
        
        #if DEBUG
        if oldStatus != hasPro {
            print("[ProEntitlementManager] 🎉 Pro status changed: \(oldStatus) → \(hasPro)")
            if hasPro {
                print("[ProEntitlementManager] ✅ User is now PRO! Unlocking all features...")
            } else {
                print("[ProEntitlementManager] ❌ User is no longer PRO. Locking features...")
            }
        } else {
            print("[ProEntitlementManager] ℹ️ Pro status unchanged: \(hasPro) (found \(foundTransactions.count) valid transactions)")
        }
        #endif
    }

    func purchase(_ product: Product) async {
        #if DEBUG
        print("[ProEntitlementManager] 💳 Starting purchase for: \(product.id)")
        print("[ProEntitlementManager] 💰 Product price: \(product.displayPrice)")
        #endif
        
        lastErrorMessage = nil
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                #if DEBUG
                print("[ProEntitlementManager] ✅ Purchase successful! Verifying transaction...")
                #endif
                guard case .verified(let transaction) = verification else {
                    #if DEBUG
                    print("[ProEntitlementManager] ❌ Purchase verification failed")
                    #endif
                    lastErrorMessage = "Purchase could not be verified."
                    return
                }
                #if DEBUG
                print("[ProEntitlementManager] ✅ Transaction verified: \(transaction.productID)")
                print("[ProEntitlementManager] 📝 Transaction date: \(transaction.purchaseDate)")
                if let expirationDate = transaction.expirationDate {
                    print("[ProEntitlementManager] 📅 Expiration date: \(expirationDate)")
                }
                #endif
                await transaction.finish()
                #if DEBUG
                print("[ProEntitlementManager] ✅ Transaction finished. Refreshing entitlement...")
                #endif
                await refreshEntitlement()

            case .userCancelled:
                #if DEBUG
                print("[ProEntitlementManager] ⏸️ User cancelled purchase")
                #endif
                break
            case .pending:
                #if DEBUG
                print("[ProEntitlementManager] ⏳ Purchase pending (requires Apple ID confirmation)")
                #endif
                lastErrorMessage = "Purchase pending. Please complete on your Apple ID."
            @unknown default:
                #if DEBUG
                print("[ProEntitlementManager] ❓ Unknown purchase result")
                #endif
                break
            }
        } catch {
            #if DEBUG
            print("[ProEntitlementManager] ❌ Purchase failed with error: \(error.localizedDescription)")
            print("[ProEntitlementManager] Error details: \(error)")
            #endif
            lastErrorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        #if DEBUG
        print("[ProEntitlementManager] 🔄 Restoring purchases...")
        #endif
        lastErrorMessage = nil
        do {
            try await AppStore.sync()
            #if DEBUG
            print("[ProEntitlementManager] ✅ AppStore sync completed. Refreshing entitlement...")
            #endif
            await refreshEntitlement()
        } catch {
            #if DEBUG
            print("[ProEntitlementManager] ❌ Restore failed: \(error.localizedDescription)")
            print("[ProEntitlementManager] Error details: \(error)")
            #endif
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

