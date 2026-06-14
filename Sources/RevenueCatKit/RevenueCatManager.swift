import RevenueCat
import Foundation

// MARK: - Purchase Result Status
// Used to identify purchase response state after RevenueCat transaction.
public enum PurchaseStatus {
    case purchased
    case cancelled
    case notActive
}

// MARK: - Active Plan Information Model
// Contains current active subscription/lifetime purchase details.
public struct PlanStatus {
    public let productId: String
    public let planDuration: String
    public let productPrice: String
    public let expirationDate: Date?
    public let isTrial: Bool
    public let daysRemaining: Int
    public let billType: String
}

// MARK: - RevenueCat Subscription Manager
// Thread-safe reusable manager for handling In-App Purchases.
// Supports: Subscription, Lifetime Purchase, Restore and Plan Details.
@MainActor
public final class RevenueCatManager {
    
    public static let shared = RevenueCatManager()
    public private(set) var isPremium = false

    private var entitlementID = ""
    private var isConfigured = false
    private var packages: [Package] = []

    private init() {}

    // MARK: - Configure RevenueCat SDK
    // Call once on app launch before using any purchase APIs.
    public func configureRevenueCat(
        userId: String? = nil,
        apiKey: String,
        entitlementID: String
    ) {

        guard !isConfigured else { return }

        Purchases.configure(
            withAPIKey: apiKey,
            appUserID: userId
        )

        self.entitlementID = entitlementID
        self.isConfigured = true
    }

    // MARK: - Load Available Offers
    // Fetch subscription and lifetime packages from RevenueCat Offering.
    public func fetchOfferings(
        completion: @escaping (Result<[Package], Error>) -> Void
    ) {

        Purchases.shared.getOfferings { offerings, error in

            Task { @MainActor in

                if let error {
                    completion(.failure(error))
                    return
                }

                let list = offerings?.current?.availablePackages ?? []
                self.packages = list

                completion(.success(list))
            }
        }
    }

    // MARK: - Purchase Product
    // Handles purchase flow and validates premium access after purchase.
    public func purchase(
        package: Package,
        completion: @escaping (Result<PurchaseStatus, Error>) -> Void
    ) {

        Purchases.shared.purchase(package: package) {
            _,
            customerInfo,
            error,
            cancelled in

            Task { @MainActor in

                if let error {
                    completion(.failure(error))
                    return
                }

                if cancelled {
                    completion(.success(.cancelled))
                    return
                }

                self.updatePremium(customerInfo)

                completion(
                    .success(
                        self.isPremium ? .purchased : .notActive
                    )
                )
            }
        }
    }

    // MARK: - Check Active Premium Status
    // Validate current user entitlement and update cached premium state.
    public func isUserSubscribed(
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {

        Purchases.shared.getCustomerInfo { info, error in

            Task { @MainActor in

                if let error {
                    completion(.failure(error))
                    return
                }

                self.updatePremium(info)

                completion(.success(self.isPremium))
            }
        }
    }

    // MARK: - Restore Purchases
    // Restore previous App Store purchases and refresh premium status.
    public func restorePurchases(
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {

        Purchases.shared.restorePurchases { info, error in

            Task { @MainActor in

                if let error {
                    completion(.failure(error))
                    return
                }

                self.updatePremium(info)

                completion(.success(self.isPremium))
            }
        }
    }

    // MARK: - Current Active Plan Details
    // Returns subscription/lifetime information for UI display.
    public func getCurrentPlanStatus(
        completion: @escaping (PlanStatus?) -> Void
    ) {

        Purchases.shared.getCustomerInfo { customerInfo, _ in

            Task { @MainActor in

                guard let customerInfo else {
                    completion(nil)
                    return
                }

                // MARK: - Active Subscription Only
                // Return only current active subscription plan.
                // Ignore consumable and other purchases.
                guard let productId = customerInfo.activeSubscriptions.first else {
                    completion(nil)
                    return
                }

                let expiry = customerInfo.expirationDate(
                    forProductIdentifier: productId
                )

                let daysRemaining: Int

                if let expiry {
                    daysRemaining = Calendar.current.dateComponents(
                        [.day],
                        from: Date(),
                        to: expiry
                    ).day ?? 0
                } else {
                    daysRemaining = -1
                }

                let plan = PlanStatus(
                    productId: productId,
                    planDuration: "Subscription",
                    productPrice: "",
                    expirationDate: expiry,
                    isTrial: false,
                    daysRemaining: daysRemaining,
                    billType: "Recurring"
                )

                completion(plan)
            }
        }
    }

    // MARK: - Premium Validation Helper
    // Only Auto Renewable Subscription and Non-Consumable Lifetime unlock premium.
    // Consumable and Non-Renewing one-time plans are ignored.
    private func updatePremium(
        _ customerInfo: CustomerInfo?
    ) {

        guard !entitlementID.isEmpty,
              let customerInfo else {
            isPremium = false
            return
        }

        // MARK: - Check Active Subscription First
        // RevenueCat entitlement can point to consumable/non-consumable product.
        // So validate activeSubscriptions separately for subscription plans.
        if !customerInfo.activeSubscriptions.isEmpty {
            isPremium = true
            return
        }

        // MARK: - Check Lifetime Purchase Only
        guard
            let entitlement = customerInfo.entitlements.all[entitlementID],
            entitlement.isActive
        else {
            isPremium = false
            return
        }

        let productId = entitlement.productIdentifier

        guard let product = packages.first(where: {
            $0.storeProduct.productIdentifier == productId
        })?.storeProduct else {
            isPremium = false
            return
        }

        switch product.productType {
        case .nonConsumable:
            // Lifetime premium purchase
            isPremium = true

        case .autoRenewableSubscription:
            // Extra fallback check
            isPremium = true

        case .consumable,
             .nonRenewableSubscription:
            // Consumable credits / one time plans ignored
            isPremium = false

        @unknown default:
            isPremium = false
        }
    }
}
