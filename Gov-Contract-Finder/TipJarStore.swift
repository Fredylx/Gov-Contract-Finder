import Foundation
import Observation
import OSLog
import StoreKit

@MainActor
@Observable
final class TipJarStore {
    enum TipTier: String, CaseIterable, Identifiable {
        case small
        case medium
        case large

        var id: String { rawValue }

        var title: String {
            switch self {
            case .small: return "Small Tip"
            case .medium: return "Medium Tip"
            case .large: return "Large Tip"
            }
        }

        var icon: String {
            switch self {
            case .small: return "cup.and.saucer.fill"
            case .medium: return "heart.fill"
            case .large: return "sparkles"
            }
        }

        var fallbackPrice: String {
            switch self {
            case .small: return "$0.99"
            case .medium: return "$4.99"
            case .large: return "$14.99"
            }
        }

        var productID: String {
            switch self {
            case .small: return "com.fredy.lopez.govcontractfinder.tip.small"
            case .medium: return "com.fredy.lopez.govcontractfinder.tip.medium"
            case .large: return "com.fredy.lopez.govcontractfinder.tip.large"
            }
        }
    }

    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "TipJar")
    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    private(set) var productsByTier: [TipTier: Product] = [:]
    var isLoadingProducts = false
    var purchasingTierID: String?
    var statusMessage: String?

    func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true

        updatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }

        await loadProductsIfNeeded()
    }

    func loadProductsIfNeeded(force: Bool = false) async {
        guard !isLoadingProducts else { return }
        guard force || productsByTier.isEmpty else { return }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let ids = Set(TipTier.allCases.map(\.productID))
            let products = try await Product.products(for: ids)
            var mapped: [TipTier: Product] = [:]

            for product in products {
                if let tier = TipTier.allCases.first(where: { $0.productID == product.id }) {
                    mapped[tier] = product
                }
            }

            productsByTier = mapped
            if mapped.isEmpty {
                statusMessage = "Tip options are not available right now."
            } else {
                statusMessage = nil
            }
        } catch {
            statusMessage = "Unable to load tip options. Please try again."
            logger.error("loadProducts failed error=\(error.localizedDescription, privacy: .public)")
        }
    }

    func price(for tier: TipTier) -> String {
        productsByTier[tier]?.displayPrice ?? tier.fallbackPrice
    }

    func purchase(_ tier: TipTier) async {
        guard purchasingTierID == nil else { return }

        if productsByTier[tier] == nil {
            await loadProductsIfNeeded(force: true)
        }

        guard let product = productsByTier[tier] else {
            statusMessage = "This tip option is unavailable right now."
            return
        }

        purchasingTierID = tier.id
        defer { purchasingTierID = nil }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await finishIfTipTransaction(transaction)
                    statusMessage = "Thanks for supporting Gov Contract Finder."
                case .unverified(_, let error):
                    statusMessage = "Purchase could not be verified."
                    logger.error("purchase unverified error=\(error.localizedDescription, privacy: .public)")
                }
            case .pending:
                statusMessage = "Purchase is pending approval."
            case .userCancelled:
                statusMessage = "Purchase canceled."
            @unknown default:
                statusMessage = "Purchase failed. Please try again."
            }
        } catch {
            statusMessage = "Purchase failed. Please try again."
            logger.error("purchase failed tier=\(tier.rawValue, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
        }
    }

    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            switch update {
            case .verified(let transaction):
                await finishIfTipTransaction(transaction)
            case .unverified(_, let error):
                logger.error("transaction update unverified error=\(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func finishIfTipTransaction(_ transaction: Transaction) async {
        guard TipTier.allCases.contains(where: { $0.productID == transaction.productID }) else {
            return
        }

        await transaction.finish()
        logger.debug("transaction finished productID=\(transaction.productID, privacy: .public)")
    }
}
