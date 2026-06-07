import ClerkKit
import SwiftUI

struct BootstrapView: View {
    @Environment(SessionStore.self) private var session
    @Environment(Clerk.self) private var clerk

    var body: some View {
        Group {
            if session.isBootstrapping {
                SpriteOverlayView(preset: .careLogOpening)
            } else if let error = session.bootstrapError {
                VStack(spacing: 12) {
                    SpriteOverlayView(preset: .errorRetry, mode: .inline, size: .small)
                    Button("Retry") { Task { await session.bootstrap() } }
                        .buttonStyle(.borderedProminent)
                        .tint(StarkTheme.primary)
                }
                .padding()
            } else {
                SpriteOverlayView(preset: .careLogOpening)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StarkTheme.background)
        .task {
            session.configure(clerk: clerk)
            await UserSyncService(apiClient: session.apiClient).syncCurrentUser(clerk: clerk)
            await session.bootstrap()
        }
    }
}
