//
//  SwiftUIDemoApp.swift
//  SwiftUIDemo
//
//  Created by Nexios Technologies on 18/11/25.
//

import SwiftUI
import RevenueCatKit

@main
struct SwiftUIDemoApp: App {
    init() {
        // Configure RevenueCatManager on startup
        RevenueCatManager.shared.configureRevenueCat(
            apiKey: "appl_hhuALfUggeCVFmRMuOrayPFcCMA",
            entitlementID: "premium"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
