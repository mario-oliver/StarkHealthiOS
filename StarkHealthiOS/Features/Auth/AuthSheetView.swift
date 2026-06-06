import ClerkKit
import ClerkKitUI
import SwiftUI

struct AuthSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AuthView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    AuthSheetView()
        .environment(Clerk.shared)
}
