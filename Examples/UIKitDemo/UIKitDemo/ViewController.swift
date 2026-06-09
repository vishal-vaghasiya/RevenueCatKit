//
//  ViewController.swift
//  UIKitDemo
//

import UIKit
import RevenueCatKit
import RevenueCat

class ViewController: UIViewController {

    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "RevenueCatKit UIKit Demo"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let subStatusTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Subscription Status"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "FREE MEMBER"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .orange
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkStatusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Check Subscription", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let restoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Restore Purchases", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.tintColor = .systemBlue
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let fetchOfferingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Fetch & Purchase First Offering", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let getPlanStatusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Get Plan Status Details", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.tintColor = .systemGreen
        button.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let consoleTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .black
        textView.textColor = .green
        textView.layer.cornerRadius = 8
        textView.text = "Console Output:\n"
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private var availablePackages: [Package] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupActions()
        log("ViewController loaded. Ready to interact.")
        
        // Initial subscription check
        checkSubscription()
    }

    // MARK: - Setup
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(statusCardView)
        statusCardView.addSubview(subStatusTitleLabel)
        statusCardView.addSubview(subStatusLabel)
        view.addSubview(checkStatusButton)
        view.addSubview(restoreButton)
        view.addSubview(fetchOfferingsButton)
        view.addSubview(getPlanStatusButton)
        view.addSubview(consoleTextView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusCardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            statusCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusCardView.heightAnchor.constraint(equalToConstant: 80),

            subStatusTitleLabel.topAnchor.constraint(equalTo: statusCardView.topAnchor, constant: 12),
            subStatusTitleLabel.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor, constant: 12),
            subStatusTitleLabel.trailingAnchor.constraint(equalTo: statusCardView.trailingAnchor, constant: -12),

            subStatusLabel.topAnchor.constraint(equalTo: subStatusTitleLabel.bottomAnchor, constant: 8),
            subStatusLabel.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor, constant: 12),
            subStatusLabel.trailingAnchor.constraint(equalTo: statusCardView.trailingAnchor, constant: -12),

            checkStatusButton.topAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: 20),
            checkStatusButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            checkStatusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            checkStatusButton.heightAnchor.constraint(equalToConstant: 44),

            restoreButton.topAnchor.constraint(equalTo: checkStatusButton.bottomAnchor, constant: 12),
            restoreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            restoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            restoreButton.heightAnchor.constraint(equalToConstant: 44),

            fetchOfferingsButton.topAnchor.constraint(equalTo: restoreButton.bottomAnchor, constant: 12),
            fetchOfferingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fetchOfferingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fetchOfferingsButton.heightAnchor.constraint(equalToConstant: 44),

            getPlanStatusButton.topAnchor.constraint(equalTo: fetchOfferingsButton.bottomAnchor, constant: 12),
            getPlanStatusButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            getPlanStatusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            getPlanStatusButton.heightAnchor.constraint(equalToConstant: 44),

            consoleTextView.topAnchor.constraint(equalTo: getPlanStatusButton.bottomAnchor, constant: 20),
            consoleTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            consoleTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            consoleTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupActions() {
        checkStatusButton.addTarget(self, action: #selector(checkSubscription), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restorePurchases), for: .touchUpInside)
        fetchOfferingsButton.addTarget(self, action: #selector(fetchAndPurchaseFirstOffering), for: .touchUpInside)
        getPlanStatusButton.addTarget(self, action: #selector(getPlanStatus), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func checkSubscription() {
        log("Checking subscription status...")
        RevenueCatManager.shared.isUserSubscribed { [weak self] subscribed, error in
            guard let self = self else { return }
            self.subStatusLabel.text = subscribed ? "ACTIVE PRO MEMBER" : "FREE MEMBER"
            self.subStatusLabel.textColor = subscribed ? .systemGreen : .systemOrange
            if let error = error {
                self.log("Error: \(error.localizedDescription)")
            } else {
                self.log(subscribed ? "Success: User is subscribed." : "Success: User is NOT subscribed.")
            }
        }
    }

    @objc private func restorePurchases() {
        log("Restoring previous purchases...")
        RevenueCatManager.shared.restorePurchases { [weak self] success, error in
            guard let self = self else { return }
            self.subStatusLabel.text = success ? "ACTIVE PRO MEMBER" : "FREE MEMBER"
            self.subStatusLabel.textColor = success ? .systemGreen : .systemOrange
            if let error = error {
                self.log("Error: \(error.localizedDescription)")
            } else {
                self.log(success ? "Success: Restored active subscription." : "Result: No active subscription restored.")
            }
        }
    }

    @objc private func fetchAndPurchaseFirstOffering() {
        log("Fetching available offerings...")
        RevenueCatManager.shared.fetchOfferings { [weak self] packages in
            guard let self = self else { return }
            self.availablePackages = packages
            self.log("Fetched \(packages.count) packages.")
            
            for (index, package) in packages.enumerated() {
                let product = package.storeProduct
                self.log("  [\(index)] ID: \(product.productIdentifier) | Name: \(product.localizedTitle) | Price: \(product.localizedPriceString)")
            }
            
            if let firstPackage = packages.first {
                let product = firstPackage.storeProduct
                
                self.log("Automatically purchasing package: \(product.localizedTitle)...")
                
                RevenueCatManager.shared.purchase(package: firstPackage) { success, error in
                    
                    if let error = error {
                        self.log("Error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard success else {
                        self.log("Failed: Purchase failed or canceled.")
                        return
                    }
                    
                    if product.productType == .consumable {
                        // Credit pack purchase only.
                        // Do not enable premium/remove ads.
                        self.log("Success: Credit pack purchased. Add credits only.")
                        
                        self.checkSubscription()
                        
                    } else {
                        // Subscription / Lifetime purchase.
                        // Verify entitlement before unlocking premium.
                        RevenueCatManager.shared.isUserSubscribed { subscribed, error in
                            self.subStatusLabel.text = subscribed ? "ACTIVE PRO MEMBER" : "FREE MEMBER"
                            self.subStatusLabel.textColor = subscribed ? .systemGreen : .systemOrange
                            
                            self.log(subscribed ? "Success: Premium activated." : "Purchase success but no active premium entitlement.")
                        }
                    }
                }
            } else {
                self.log("Warning: No packages available to purchase.")
            }
        }
    }

    @objc private func getPlanStatus() {
        log("Retrieving plan status...")
        RevenueCatManager.shared.getCurrentPlanStatus { [weak self] planStatuses in
            guard let self = self else { return }
            self.log("Retrieved \(planStatuses.count) plan statuses.")
            for status in planStatuses {
                self.log("--- Plan Info ---")
                self.log("Product ID: \(status.productId)")
                self.log("Duration: \(status.planDuration)")
                self.log("Price: \(status.productPrice)")
                self.log("Expiration: \(status.expirationDate?.description ?? "Lifetime")")
                self.log("Trial?: \(status.isTrial)")
                self.log("Days Remaining: \(status.daysRemaining)")
                self.log("Billing Type: \(status.billType)")
            }
        }
    }

    // MARK: - Helper Log
    private func log(_ message: String) {
        print(message)
        DispatchQueue.main.async {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: Date())
            self.consoleTextView.text += "[\(timeString)] \(message)\n"
            
            // Auto scroll console
            let range = NSRange(location: self.consoleTextView.text.count - 1, length: 1)
            self.consoleTextView.scrollRangeToVisible(range)
        }
    }
}
