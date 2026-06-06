import ClerkKit
import Foundation

struct UserSyncService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func syncCurrentUser(clerk: Clerk) async {
        guard let user = clerk.user else { return }

        let email = user.primaryEmailAddress?.emailAddress
            ?? user.emailAddresses.first?.emailAddress

        guard let email, !email.isEmpty else {
            print("UserSyncService: waiting for email address")
            return
        }

        do {
            guard let token = try await clerk.auth.getToken() else {
                print("UserSyncService: no auth token available")
                return
            }

            let payload = CreateUserPayload(
                id: user.id,
                email: email,
                firstName: user.firstName,
                lastName: user.lastName
            )

            try await apiClient.createUser(token: token, payload: payload)
            print("UserSyncService: user synced successfully")
        } catch {
            print("UserSyncService: sync failed — \(error.localizedDescription)")
        }
    }
}
