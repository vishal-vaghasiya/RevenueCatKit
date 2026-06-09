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
            apiKey: "appl_mock_api_key_swiftui",
            entitlementID: "pro_access"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
