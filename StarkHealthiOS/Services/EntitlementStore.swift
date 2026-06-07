import Foundation
import StoreKit

@MainActor
@Observable
final class EntitlementStore {
    var entitlement: EntitlementResult?
    var isLoading = false
    var error: String?

    var hasPro: Bool { entitlement?.hasPro ?? false }
    var hasBasic: Bool { entitlement?.hasBasic ?? false }

    private let apiClient: APIClient
    private let storeKit = StoreKitService.shared

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            entitlement = try await apiClient.getSubscription().entitlement
        } catch {
            self.error = error.localizedDescription
        }
    }

    func purchase(product: Product) async throws {
        let (verification, transaction) = try await storeKit.purchase(product)
        let jws = try storeKit.signedTransactionJWS(from: verification)
        let payload = try await apiClient.verifyAppleTransaction(signedTransaction: jws)
        entitlement = payload.entitlement
        await transaction.finish()
    }

    func handleTransactionUpdate(_ verification: VerificationResult<Transaction>, transaction: Transaction) async {
        do {
            let jws = try storeKit.signedTransactionJWS(from: verification)
            let payload = try await apiClient.verifyAppleTransaction(signedTransaction: jws)
            entitlement = payload.entitlement
        } catch {
            self.error = error.localizedDescription
        }
    }
}
