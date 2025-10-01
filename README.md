

# RevenueCatKit

RevenueCatKit is a lightweight Swift library that makes it easy to integrate RevenueCat subscriptions and in-app purchases into your iOS app. With a simple interface, you can fetch offerings, handle purchases, check subscription status, restore purchases, and more – all with minimal setup.

## Features
- Fetch available offerings and products from RevenueCat
- Purchase subscriptions or in-app products
- Check if a user has an active subscription
- Restore previous purchases
- Get current plan status with a simple struct

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

Before using RevenueCatKit, you need to configure it with your RevenueCat API key and dynamic `entitlementID` (the identifier you set up in the RevenueCat dashboard for your product).

```swift
import RevenueCatKit

// Typically, you configure this early in your app's lifecycle, e.g. in AppDelegate or at launch.
RevenueCatKit.configure(
    apiKey: "your_revenuecat_api_key",
    entitlementID: "your_dynamic_entitlement_id" // e.g. "pro_access"
)
```

> **Tip:** You can set `entitlementID` dynamically based on your app's logic or user selection.

---

## 3. Usage Examples

### Fetch Available Offerings

List all available products and packages from your RevenueCat dashboard.

```swift
RevenueCatKit.shared.fetchOfferings { result in
    switch result {
    case .success(let offerings):
        // offerings.current contains the current offering
        if let packages = offerings.current?.availablePackages {
            for package in packages {
                print("Package: \(package.identifier), price: \(package.product.price)")
            }
        }
    case .failure(let error):
        print("Failed to fetch offerings: \(error)")
    }
}
```

### Purchase a Package

Purchase a package (e.g., monthly subscription).

```swift
// Assume you have a Package object (e.g., from fetchOfferings)
RevenueCatKit.shared.purchase(package) { result in
    switch result {
    case .success(let transaction):
        print("Purchase successful: \(transaction.productIdentifier)")
    case .failure(let error):
        print("Purchase failed: \(error)")
    }
}
```

### Check Subscription Status

Check if the user currently has an active subscription for your entitlement.

```swift
RevenueCatKit.shared.isSubscribed { isActive in
    if isActive {
        print("User has an active subscription!")
    } else {
        print("No active subscription.")
    }
}
```

### Restore Purchases

Restore previous purchases (useful when users reinstall or switch devices).

```swift
RevenueCatKit.shared.restorePurchases { result in
    switch result {
    case .success(let restored):
        print("Restored: \(restored)")
    case .failure(let error):
        print("Restore failed: \(error)")
    }
}
```

### Get Current Plan Status

Retrieve a summary of the user's current subscription plan.

```swift
RevenueCatKit.shared.getCurrentPlanStatus { status in
    if status.isActive {
        print("Active plan: \(status.productIdentifier ?? "unknown")")
        print("Will renew: \(status.willRenew)")
        print("Expires at: \(status.expirationDate?.description ?? "unknown")")
    } else {
        print("No active plan.")
    }
}
```

---

## 4. `PlanStatus` Struct Explained

The `PlanStatus` struct provides a simple summary of the user's current subscription state:

```swift
public struct PlanStatus {
    public let isActive: Bool              // True if the user has an active entitlement
    public let willRenew: Bool             // True if the subscription will renew
    public let expirationDate: Date?       // Expiration date of the current plan
    public let productIdentifier: String?  // The product ID of the active plan
}
```

- **isActive**: Whether the user has an active subscription for the configured entitlement.
- **willRenew**: Whether the subscription is set to auto-renew.
- **expirationDate**: When the current plan will expire (if available).
- **productIdentifier**: The identifier of the currently active product.

---

## 5. Notes & Best Practices

- **Dynamic Entitlement**: Always ensure the `entitlementID` matches the one you configured in RevenueCat dashboard. You can set this dynamically to support different products or plans.
- **Privacy**: RevenueCat handles purchase validation and user privacy securely. You do not need to manage receipts directly.
- **Testing**: Use RevenueCat's sandbox environment and Apple's StoreKit testing tools to simulate purchases during development.
- **Error Handling**: Always handle failures in your UI to provide good feedback to users (e.g., for network errors or purchase failures).
- **Support**: For more advanced features (user IDs, promotional offers, etc.), see the [RevenueCat documentation](https://docs.revenuecat.com/).

---

## 6. Resources

- [RevenueCat Documentation](https://docs.revenuecat.com/)
- [RevenueCatKit GitHub](https://github.com/vishalvaghasiya-ios/RevenueCatKit)

---

## License

MIT License. See [LICENSE](LICENSE) for details.
