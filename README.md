# RevenueCatKit

RevenueCatKit is a lightweight Swift library that makes it easy to integrate RevenueCat subscriptions and in-app purchases into your iOS app. With a simple interface, you can fetch offerings, handle purchases, check subscription status, restore purchases, and retrieve active plan details – all with minimal setup.

## Features
- Fetch available offerings and packages from RevenueCat
- Purchase subscriptions, non-consumables, or consumable products
- Check if a user has an active subscription (automatically filters out consumables)
- Restore previous purchases (only returns success if subscription or non-consumable plans are active)
- Get current plan status with a structured, detailed object (consumables excluded)

---

## 1. Installation

### Swift Package Manager (Recommended)

1. In Xcode, go to **File > Add Packages...**
2. Enter the RevenueCatKit repository URL:
    ```
    https://github.com/vishalvaghasiya-ios/RevenueCatKit.git
    ```
3. Select the latest version and add the package to your target.

---

## 2. Configuration

Before using RevenueCatKit, configure the manager with your RevenueCat API key and your configured entitlement ID. Typically, you do this early in your app's lifecycle (e.g., in `AppDelegate` or the SwiftUI App `init`).

```swift
import RevenueCatKit

// Configure in SwiftUI App init or AppDelegate didFinishLaunchingWithOptions
RevenueCatManager.shared.configureRevenueCat(
    apiKey: "your_revenuecat_api_key",
    entitlementID: "your_entitlement_id" // e.g. "pro_access"
)
```

---

## 3. Subscription & Consumable Rules

To ensure a consistent user experience, the library distinguishes between product types:
- **Active Subscription (Subscribed):** A user is considered active/subscribed ONLY if they have purchased an active **Subscription Base Plan** (auto-renewable or non-renewable) or a **Non-Consumable** plan (e.g., a lifetime/one-time unlock).
- **Consumable Plans:** Consumable plans (e.g., buying coins, credits, or one-off consumable packs) do **NOT** qualify as active subscriptions. Methods like `isUserSubscribed`, `restorePurchases`, and `purchase` completion will automatically filter out consumable products.
- **Active Plan Status:** Consumable products are automatically filtered out from `getCurrentPlanStatus`.

---

## 4. Usage Examples

### Fetch Available Offerings

Retrieve the packages configured in your RevenueCat offerings:

```swift
RevenueCatManager.shared.fetchOfferings { packages in
    for package in packages {
        let product = package.storeProduct
        print("Product: \(product.localizedTitle), Price: \(product.localizedPriceString)")
    }
}
```

### Purchase a Package

Purchase a subscription or in-app package. The completion handler returns `(isSubscribed, error)`. `isSubscribed` will be `true` if the purchase completes successfully and unlocks an active subscription base plan or non-consumable (consumables will return `false`).

```swift
// Assume package is obtained from fetchOfferings
RevenueCatManager.shared.purchase(package: package) { isSubscribed, error in
    if let error = error {
        print("Purchase error: \(error.localizedDescription)")
    } else if isSubscribed {
        print("Successfully purchased and unlocked subscription access!")
    } else {
        print("Purchase failed, canceled, or was a consumable.")
    }
}
```

### Check Subscription Status

Determine if the user currently has an active subscription or non-consumable unlocked. Consumables are ignored.

```swift
RevenueCatManager.shared.isUserSubscribed { isSubscribed, error in
    if let error = error {
        print("Check subscription error: \(error.localizedDescription)")
    } else if isSubscribed {
        print("User has active subscription access!")
    } else {
        print("User does not have active subscription access.")
    }
}
```

### Restore Purchases

Restore previous purchases for the configured entitlement. The completion handler returns `true` if an active subscription base plan or non-consumable is recovered.

```swift
RevenueCatManager.shared.restorePurchases { isSubscribed, error in
    if let error = error {
        print("Restore error: \(error.localizedDescription)")
    } else if isSubscribed {
        print("Subscription restored successfully!")
    } else {
        print("Restore completed, but no active subscription/non-consumable was found.")
    }
}
```

### Get Current Plan Status

Retrieve detailed status information about all active plans. Consumable plans are excluded.

```swift
RevenueCatManager.shared.getCurrentPlanStatus { planStatuses in
    for status in planStatuses {
        print("--- Plan Status ---")
        print("Product ID: \(status.productId)")
        print("Price: \(status.productPrice)")
        print("Duration: \(status.planDuration)")
        print("Trial Period?: \(status.isTrial)")
        print("Billing details: \(status.billType)")
        if let expiry = status.expirationDate {
            print("Expires on: \(expiry) (Days remaining: \(status.daysRemaining))")
        }
    }
}
```

---

## 5. `PlanStatus` Struct Reference

The `PlanStatus` struct contains detailed information about an active plan:

```swift
public struct PlanStatus {
    public let productId: String          // The product ID (e.g. "com.app.monthly")
    public let planDuration: String       // e.g. "Monthly", "Yearly", "Daily", "One-time"
    public let productPrice: String       // Localized price (e.g. "$4.99")
    public let expirationDate: Date?      // Expiration date (nil for lifetime/non-consumable)
    public let isTrial: Bool              // True if currently in a trial period
    public let daysRemaining: Int         // Days remaining until expiration
    public let billType: String           // e.g. "Billed Monthly", "One-time Payment"
}
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
