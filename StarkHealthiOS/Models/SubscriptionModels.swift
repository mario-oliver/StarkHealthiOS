import Foundation

struct EntitlementResult: Decodable, Equatable {
    let planSlug: String?
    let hasPro: Bool
    let hasBasic: Bool
    let source: String?
    let status: String?
    let periodEnd: String?
    let cancelAtPeriodEnd: Bool
}

struct SubscriptionRecord: Decodable, Equatable {
    let id: String
    let status: String
    let planSlug: String
    let source: String
    let periodEnd: String?
    let cancelAtPeriodEnd: Bool
}

struct SubscriptionPayload: Decodable, Equatable {
    let entitlement: EntitlementResult
    let subscriptions: [SubscriptionRecord]
}

struct VerifyAppleTransactionPayload: Decodable, Equatable {
    let entitlement: EntitlementResult
}

struct VerifyAppleTransactionBody: Encodable {
    let signedTransaction: String
}
