import SwiftUI
import StoreKit

struct StoreView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var iapService = IAPService.shared
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text("STORE")
                            .font(AppFonts.orbitron(28, weight: .black))
                            .foregroundColor(.white)
                            .tracking(4)
                        Text("Enhance your experience")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top)

                    if iapService.isLoading {
                        ProgressView("Loading products...")
                            .foregroundColor(AppColors.textSecondary)
                            .tint(AppColors.accent)
                            .padding(.top, 40)
                    } else if iapService.products.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "cart.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.textMuted)
                            Text("Products unavailable")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textMuted)
                            Text("Please check your internet connection and try again.")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textDark)
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
                            .font(AppFonts.rajdhani(14, weight: .semibold))
                            .foregroundColor(AppColors.accent)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
                .opacity(isAppeared ? 1 : 0)
                .offset(y: isAppeared ? 0 : 20)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isAppeared = true
                    }
                }
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
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: iapProduct.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isBestValue ? AppColors.gold : AppColors.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isBestValue ? AppColors.gold.opacity(0.15) : AppColors.accentDim)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(iapProduct.displayName)
                        .font(AppFonts.orbitron(13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(iapProduct.description)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textMuted)
                        .lineLimit(2)
                }

                Spacer()

                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.success)
                } else {
                    Button(action: {
                        Task { await onPurchase() }
                    }) {
                        Text(product.displayPrice)
                            .font(AppFonts.orbitron(12, weight: .bold))
                            .foregroundColor(isBestValue ? .black : AppColors.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isBestValue ? AppColors.goldGradient : LinearGradient(colors: [AppColors.accentDim, AppColors.accentDim], startPoint: .leading, endPoint: .trailing))
                            )
                            .overlay(
                                isBestValue ? nil :
                                Capsule()
                                    .stroke(AppColors.accentBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isBestValue ? AppColors.gold.opacity(0.03) : Color(red: 0, green: 30/255, blue: 60/255).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isBestValue ? AppColors.gold.opacity(0.4) : AppColors.accentBorder.opacity(0.5), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            if isBestValue {
                Text("BEST VALUE")
                    .font(AppFonts.orbitron(8, weight: .heavy))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppColors.goldGradient))
                    .offset(y: -10)
            }
        }
    }
}
