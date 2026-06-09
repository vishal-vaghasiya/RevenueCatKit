//
//  ContentView.swift
//  SwiftUIDemo
//
//  Created by Nexios Technologies on 18/11/25.
//

import SwiftUI
import RevenueCatKit
import RevenueCat

struct ContentView: View {
    @State private var isSubscribed = false
    @State private var isLoading = false
    @State private var packages: [Package] = []
    @State private var planStatuses: [PlanStatus] = []
    @State private var statusMessage = "Ready"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Subscription Status Card
                    VStack(spacing: 8) {
                        Text("Subscription Status")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(isSubscribed ? "ACTIVE PRO MEMBER" : "FREE MEMBER")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(isSubscribed ? .green : .orange)
                        
                        if isSubscribed {
                            Text("Thank you for your support!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Main Action Buttons
                    HStack(spacing: 12) {
                        Button(action: checkSubscription) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Check Status")
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        
                        Button(action: restorePurchases) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Restore")
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Offerings Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Available Offers")
                                .font(.headline)
                            Spacer()
                            Button(action: fetchOfferings) {
                                Text("Reload")
                                    .font(.subheadline)
                            }
                        }
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if packages.isEmpty {
                            Text("No products loaded. Tap Reload to fetch from RevenueCat.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(packages, id: \.identifier) { package in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(package.storeProduct.localizedTitle)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Text(package.storeProduct.localizedDescription)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: { purchase(package) }) {
                                        Text(package.storeProduct.localizedPriceString)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Plan Status Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Plans Details")
                            .font(.headline)
                        
                        if planStatuses.isEmpty {
                            Text("No active subscription plan details found.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(planStatuses, id: \.productId) { status in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(status.productId)
                                            .font(.body)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Text(status.isTrial ? "Trial" : "Standard")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(status.isTrial ? Color.yellow.opacity(0.2) : Color.blue.opacity(0.2))
                                            .foregroundColor(status.isTrial ? .orange : .blue)
                                            .cornerRadius(4)
                                    }
                                    
                                    HStack {
                                        Text("Price: \(status.productPrice)")
                                        Spacer()
                                        Text("Duration: \(status.planDuration)")
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    
                                    Text(status.billType)
                                        .font(.caption)
                                        .italic()
                                        .foregroundColor(.secondary)
                                    
                                    if let expiry = status.expirationDate {
                                        Text("Expires in: \(status.daysRemaining) days (\(expiry.formatted(date: .abbreviated, time: .omitted)))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Status Footer Message
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("RevenueCatKit Demo")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                checkSubscription()
                fetchOfferings()
            }
        }
    }

    // MARK: - Actions
    
    private func checkSubscription() {
        statusMessage = "Checking subscription status..."
        RevenueCatManager.shared.isUserSubscribed { subscribed, error in
            self.isSubscribed = subscribed
            if let error = error {
                self.statusMessage = "Check subscription error: \(error.localizedDescription)"
            } else {
                self.statusMessage = subscribed ? "User is subscribed!" : "User is not subscribed."
            }
            
            // If subscribed, also load active plan details
            if subscribed {
                self.loadPlanStatus()
            } else {
                self.planStatuses = []
            }
        }
    }
    
    private func fetchOfferings() {
        isLoading = true
        statusMessage = "Fetching offerings..."
        RevenueCatManager.shared.fetchOfferings { fetchedPackages in
            self.packages = fetchedPackages
            self.isLoading = false
            self.statusMessage = "Offerings fetched successfully: \(fetchedPackages.count) packages found."
        }
    }
    
    private func purchase(_ package: Package) {
        statusMessage = "Starting purchase for \(package.storeProduct.localizedTitle)..."
        RevenueCatManager.shared.purchase(package: package) { success, error in
            self.isSubscribed = success
            if let error = error {
                self.statusMessage = "Purchase failed: \(error.localizedDescription)"
            } else {
                self.statusMessage = success ? "Purchase successful!" : "Purchase failed or canceled."
            }
            if success {
                self.loadPlanStatus()
            }
        }
    }
    
    private func restorePurchases() {
        statusMessage = "Restoring purchases..."
        RevenueCatManager.shared.restorePurchases { success, error in
            self.isSubscribed = success
            if let error = error {
                self.statusMessage = "Restore failed: \(error.localizedDescription)"
            } else {
                self.statusMessage = success ? "Purchases restored successfully!" : "Restore completed, but no active subscriptions found."
            }
            if success {
                self.loadPlanStatus()
            }
        }
    }
    
    private func loadPlanStatus() {
        RevenueCatManager.shared.getCurrentPlanStatus { statuses in
            self.planStatuses = statuses
        }
    }
}

#Preview {
    ContentView()
}
