import SwiftUI
import StoreKit

struct StoreView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var iapService = IAPService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text("STORE")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("Enhance your experience")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)

                    if iapService.isLoading {
                        ProgressView("Loading products...")
                            .foregroundColor(.white)
                            .padding(.top, 40)
                    } else if iapService.products.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "cart.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Products unavailable")
                                .foregroundColor(.gray)
                            Text("Please check your internet connection and try again.")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        // Bundle (best value)
                        if let bundleProduct = iapService.getProduct(for: .acePilotBundle) {
                            StoreItemView(
                                product: bundleProduct,
                                iapProduct: .acePilotBundle,
                                isBestValue: true,
                                isPurchased: iapService.isPurchased(.acePilotBundle)
                            ) {
                                await purchaseProduct(bundleProduct)
                            }
                        }

                        // Individual products
                        ForEach(IAPProduct.allCases.filter { $0 != .acePilotBundle }, id: \.rawValue) { iapProduct in
                            if let product = iapService.getProduct(for: iapProduct) {
                                StoreItemView(
                                    product: product,
                                    iapProduct: iapProduct,
                                    isBestValue: false,
                                    isPurchased: iapService.isPurchased(iapProduct)
                                ) {
                                    await purchaseProduct(product)
                                }
                            }
                        }
                    }

                    // Restore purchases
                    Button(action: {
                        Task {
                            await iapService.restorePurchases()
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.cyan)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Store")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if iapService.products.isEmpty {
                await iapService.loadProducts()
            }
        }
    }

    private func purchaseProduct(_ product: Product) async {
        do {
            try await iapService.purchase(product)
        } catch {
            print("[StoreView] Purchase error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Store Item

struct StoreItemView: View {
    let product: Product
    let iapProduct: IAPProduct
    let isBestValue: Bool
    let isPurchased: Bool
    let onPurchase: () async -> Void

    var body: some View {
        VStack(spacing: 12) {
            if isBestValue {
                Text("BEST VALUE")
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(4)
            }

            HStack(spacing: 16) {
                Image(systemName: iapProduct.icon)
                    .font(.title2)
                    .foregroundColor(isBestValue ? .yellow : .cyan)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(iapProduct.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(iapProduct.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        Task { await onPurchase() }
                    }) {
                        Text(product.displayPrice)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isBestValue ? Color.yellow.opacity(0.8) : Color.blue)
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isBestValue ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
    }
}
