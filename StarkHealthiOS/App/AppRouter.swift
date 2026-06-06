import ClerkKit
import SwiftUI

struct AppRouter: View {
    @Environment(Clerk.self) private var clerk
    @State private var session = SessionStore()

    var body: some View {
        Group {
            if clerk.user == nil {
                LandingView()
            } else {
                switch session.flow {
                case .bootstrap:
                    BootstrapView()
                case .onboarding:
                    OnboardingView()
                case .join:
                    JoinView()
                case .dashboard:
                    DashboardShellView()
                }
            }
        }
        .environment(session)
        .onChange(of: clerk.user?.id) { _, userId in
            if userId != nil {
                session.flow = .bootstrap
                Task { await session.bootstrap() }
            } else {
                session.dogs = []
                session.activeDogId = nil
                session.flow = .bootstrap
            }
        }
    }
}

#Preview {
    AppRouter()
        .environment(Clerk.shared)
}
