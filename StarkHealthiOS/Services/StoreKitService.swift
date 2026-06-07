import Foundation
import StoreKit

@MainActor
final class StoreKitService {
    static let shared = StoreKitService()

    private(set) var products: [Product] = []
    private var updatesTask: Task<Void, Never>?

    private init() {}

    var productIds: [String] {
        [AppConfig.appleProductPro, AppConfig.appleProductBasic].filter { !$0.isEmpty }
    }

    func startListening(onUpdate: @escaping (VerificationResult<Transaction>, Transaction) async -> Void) {
        updatesTask?.cancel()
        updatesTask = Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await onUpdate(result, transaction)
                await transaction.finish()
            }
        }
    }

    func loadProducts() async throws {
        guard !productIds.isEmpty else {
            products = []
            return
        }
        products = try await Product.products(for: productIds)
            .sorted { $0.price < $1.price }
    }

    func purchase(_ product: Product) async throws -> (VerificationResult<Transaction>, Transaction) {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                return (verification, transaction)
            case .unverified:
                throw StoreKitServiceError.unverifiedTransaction
            }
        case .userCancelled:
            throw StoreKitServiceError.userCancelled
        case .pending:
            throw StoreKitServiceError.pending
        @unknown default:
            throw StoreKitServiceError.unknown
        }
    }

    func signedTransactionJWS(from verification: VerificationResult<Transaction>) throws -> String {
        let jws = verification.jwsRepresentation
        guard !jws.isEmpty else {
            throw StoreKitServiceError.missingJWS
        }
        return jws
    }
}

enum StoreKitServiceError: LocalizedError {
    case unverifiedTransaction
    case userCancelled
    case pending
    case missingJWS
    case unknown

    var errorDescription: String? {
        switch self {
        case .unverifiedTransaction:
            return "Could not verify the App Store transaction."
        case .userCancelled:
            return "Purchase cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .missingJWS:
            return "Missing signed transaction from App Store."
        case .unknown:
            return "Unknown purchase error."
        }
    }
}
