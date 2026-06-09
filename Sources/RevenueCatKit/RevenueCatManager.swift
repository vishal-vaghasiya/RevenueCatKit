// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import RevenueCat

public struct PlanStatus {
    public let productId: String
    public let planDuration: String
    public let productPrice: String
    public let expirationDate: Date?
    public let isTrial: Bool
    public let daysRemaining: Int
    public let billType: String
}

public final class RevenueCatManager {

    // MARK: - Singleton
    @MainActor public static let shared = RevenueCatManager()
    private var entitlementID = String()
    private init() {}
    private var arrOfPackage: [Package] = []

    // MARK: - Configure RevenueCat
    public func configureRevenueCat(userId: String? = nil, apiKey: String, entitlementID: String) {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif
        Purchases.configure(withAPIKey: apiKey, appUserID: userId)
        
        self.entitlementID = entitlementID
    }

    // MARK: - Fetch Offerings
    public func fetchOfferings(completion: @escaping ([Package]) -> Void) {
        Purchases.shared.getOfferings { offerings, _ in
            let packages = offerings?.current?.availablePackages ?? []
            self.arrOfPackage = packages
            completion(packages)
        }
    }

    // MARK: - Purchase Package
    public func purchase(package: Package, completion: @MainActor @escaping (Bool, Error?) -> Void) {
        let entitlementID = self.entitlementID
        let packages = self.arrOfPackage
        Purchases.shared.purchase(package: package) { _, customerInfo, error, _ in
            RevenueCatManager.checkSubscriptionActive(
                for: entitlementID,
                packages: packages,
                customerInfo: customerInfo,
                error: error,
                completion: completion
            )
        }
    }

    // MARK: - Check Subscription
    public func isUserSubscribed(completion: @MainActor @escaping (Bool, Error?) -> Void) {
        let entitlementID = self.entitlementID
        let packages = self.arrOfPackage
        Purchases.shared.getCustomerInfo { customerInfo, error in
            RevenueCatManager.checkSubscriptionActive(
                for: entitlementID,
                packages: packages,
                customerInfo: customerInfo,
                error: error,
                completion: completion
            )
        }
    }

    // MARK: - Restore Purchases
    public func restorePurchases(completion: @MainActor @escaping (Bool, Error?) -> Void) {
        let entitlementID = self.entitlementID
        let packages = self.arrOfPackage
        Purchases.shared.restorePurchases { customerInfo, error in
            RevenueCatManager.checkSubscriptionActive(
                for: entitlementID,
                packages: packages,
                customerInfo: customerInfo,
                error: error,
                completion: completion
            )
        }
    }

    // MARK: - Current Plan Status
    public func getCurrentPlanStatus(completion: @MainActor @escaping ([PlanStatus]) -> Void) {
        let packages = self.arrOfPackage
        Purchases.shared.getCustomerInfo { customerInfo, _ in
            guard let customerInfo = customerInfo else {
                Task { @MainActor in
                    completion([])
                }
                return
            }

            let activeEntitlements = customerInfo.entitlements.active
            var planStatuses: [PlanStatus] = []

            for (_, entitlement) in activeEntitlements {
                let productId = entitlement.productIdentifier
                let expirationDate = entitlement.expirationDate
                let isTrial = entitlement.willRenew && entitlement.periodType == .intro

                let matchedProduct = packages.first { $0.storeProduct.productIdentifier == productId }
                
                // Filter out consumable plans from current active plan status list
                if let product = matchedProduct?.storeProduct, product.productType == .consumable {
                    continue
                }
                
                let localizedPrice = matchedProduct?.storeProduct.localizedPriceString ?? ""
                let product = matchedProduct?.storeProduct
                let subscriptionPeriod = product?.subscriptionPeriod?.unit

                let duration: String
                switch subscriptionPeriod {
                case .day: duration = "Daily"
                case .week: duration = "Weekly"
                case .month: duration = "Monthly"
                case .year: duration = "Yearly"
                default: duration = "One-time"
                }

                let billingDescription: String
                switch subscriptionPeriod {
                case .day: billingDescription = "Billed Daily"
                case .week: billingDescription = "Billed Weekly"
                case .month: billingDescription = "Billed Monthly"
                case .year: billingDescription = "Billed Annually"
                default: billingDescription = "One-time Payment"
                }

                var daysRemaining = 0
                if let expiry = expirationDate {
                    let components = Calendar.current.dateComponents([.day], from: Date(), to: expiry)
                    daysRemaining = components.day ?? 0
                }

                let status = PlanStatus(
                    productId: productId,
                    planDuration: duration,
                    productPrice: localizedPrice,
                    expirationDate: expirationDate,
                    isTrial: isTrial,
                    daysRemaining: daysRemaining,
                    billType: billingDescription
                )
                planStatuses.append(status)
            }

            Task { @MainActor in
                completion(planStatuses)
            }
        }
    }
    
    // MARK: - Helper Methods
    private static func checkSubscriptionActive(
        for entitlementID: String,
        packages: [Package],
        customerInfo: CustomerInfo?,
        error: Error?,
        completion: @MainActor @escaping (Bool, Error?) -> Void
    ) {
        if let error = error {
            Task { @MainActor in
                completion(false, error)
            }
            return
        }

        guard let entitlement = customerInfo?.entitlements.all[entitlementID], entitlement.isActive else {
            Task { @MainActor in
                completion(false, nil)
            }
            return
        }
        
        let productID = entitlement.productIdentifier
        
        // Fast path: Check cache in packages list
        if let matchedProduct = packages.first(where: { $0.storeProduct.productIdentifier == productID })?.storeProduct {
            let isActive = RevenueCatManager.isAllowedProductType(matchedProduct.productType)
            Task { @MainActor in
                completion(isActive, nil)
            }
            return
        }
        
        // Slow path: Fetch product from the store to check its type
        Purchases.shared.getProducts([productID]) { products in
            let isActive: Bool
            if let product = products.first {
                isActive = RevenueCatManager.isAllowedProductType(product.productType)
            } else {
                // Fallback: If product details cannot be fetched, we verify if there is an expirationDate.
                // Auto-renewable subscriptions have an expiration date, whereas consumables/non-consumables do not.
                isActive = entitlement.expirationDate != nil
            }
            Task { @MainActor in
                completion(isActive, nil)
            }
        }
    }
    
    private static func isAllowedProductType(_ type: StoreProduct.ProductType) -> Bool {
        switch type {
        case .autoRenewableSubscription, .nonRenewableSubscription, .nonConsumable:
            return true
        case .consumable:
            return false
        @unknown default:
            return false
        }
    }
}
