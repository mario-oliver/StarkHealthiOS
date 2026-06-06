import ClerkKit
import SwiftUI

@main
struct StarkHealthiOSApp: App {
    init() {
        Clerk.configure(publishableKey: AppConfig.clerkPublishableKey)
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(Clerk.shared)
        }
    }
}
