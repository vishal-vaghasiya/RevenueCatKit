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
    public func purchase(package: Package, completion: @MainActor @escaping (Bool) -> Void) {
        let entitlementID = self.entitlementID
        Purchases.shared.purchase(package: package) { _, customerInfo, error, _ in
            let isActive = customerInfo?.entitlements.all[entitlementID]?.isActive ?? false
            Task { @MainActor in
                completion(isActive)
            }
        }
    }

    // MARK: - Check Subscription
    public func isUserSubscribed(completion: @MainActor @escaping (Bool) -> Void) {
        let entitlementID = self.entitlementID
        Purchases.shared.getCustomerInfo { customerInfo, _ in
            let isActive = customerInfo?.entitlements.all[entitlementID]?.isActive ?? false
            Task { @MainActor in
                completion(isActive)
            }
        }
    }

    // MARK: - Restore Purchases
    public func restorePurchases(completion: @MainActor @escaping (Bool) -> Void) {
        let entitlementID = self.entitlementID
        Purchases.shared.restorePurchases { customerInfo, _ in
            let isActive = customerInfo?.entitlements.all[entitlementID]?.isActive ?? false
            Task { @MainActor in
                completion(isActive)
            }
        }
    }

    // MARK: - Current Plan Status
    public func getCurrentPlanStatus(completion: @MainActor @escaping ([PlanStatus]) -> Void) {
        let entitlementID = self.entitlementID
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
}
