import StoreKit
import FirebaseFirestore

/// Manages in-app purchases using StoreKit 2
@MainActor
class IAPService: ObservableObject {
    static let shared = IAPService()

    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false

    private var updateListenerTask: Task<Void, Error>?
    private let db = Firestore.firestore()

    private init() {
        loadLocalPurchases()
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public API

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = IAPProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: Set(productIds))
            products.sort { $0.price < $1.price }
            print("[IAPService] Loaded \(products.count) products")
        } catch {
            print("[IAPService] Failed to load products: \(error.localizedDescription)")
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await recordPurchase(transaction.productID)
            await transaction.finish()
            print("[IAPService] Purchase successful: \(transaction.productID)")

        case .userCancelled:
            print("[IAPService] User cancelled purchase")

        case .pending:
            print("[IAPService] Purchase pending")

        @unknown default:
            print("[IAPService] Unknown purchase result")
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()

            for await result in Transaction.currentEntitlements {
                if let transaction = try? checkVerified(result) {
                    await recordPurchase(transaction.productID)
                }
            }
            print("[IAPService] Restore complete. Purchased: \(purchasedProducts)")
        } catch {
            print("[IAPService] Restore failed: \(error.localizedDescription)")
        }
    }

    func isPurchased(_ product: IAPProduct) -> Bool {
        if purchasedProducts.contains(product.rawValue) { return true }
        // Bundle includes all sub-products
        if product != .acePilotBundle && purchasedProducts.contains(IAPProduct.acePilotBundle.rawValue) {
            return IAPProduct.bundleContents.contains(product)
        }
        return false
    }

    func isAdsRemoved() -> Bool {
        isPurchased(.removeAds)
    }

    func getProduct(for iapProduct: IAPProduct) -> Product? {
        products.first { $0.id == iapProduct.rawValue }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    let productID = transaction.productID
                    await MainActor.run {
                        self?.purchasedProducts.insert(productID)
                        self?.savePurchasesLocally()
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func recordPurchase(_ productId: String) async {
        purchasedProducts.insert(productId)

        // Handle bundle — mark all sub-products as purchased
        if productId == IAPProduct.acePilotBundle.rawValue {
            for item in IAPProduct.bundleContents {
                purchasedProducts.insert(item.rawValue)
            }
        }

        savePurchasesLocally()
        await syncPurchasesToCloud()
    }

    // MARK: - Persistence

    private func savePurchasesLocally() {
        let array = Array(purchasedProducts)
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: GameConstants.StorageKeys.iapPurchases)
        }
    }

    private func loadLocalPurchases() {
        guard let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.iapPurchases),
              let array = try? JSONDecoder().decode([String].self, from: data) else { return }
        purchasedProducts = Set(array)
    }

    private func syncPurchasesToCloud() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let purchases = Array(purchasedProducts)
        do {
            try await db.collection("users").document(userId).updateData([
                "purchases": purchases,
                "purchasesUpdatedAt": Date().timeIntervalSince1970 * 1000
            ])
        } catch {
            print("[IAPService] Cloud sync failed: \(error.localizedDescription)")
        }
    }
}

// Import needed for Auth reference
import FirebaseAuth
