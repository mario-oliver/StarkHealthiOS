import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    @State private var products: [Product] = []
    @State private var loading = true
    @State private var purchasingId: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose a plan")
                        .font(.title2.bold())

                    Text("Subscribe through the App Store. Your Stark Health account works on web and iOS.")
                        .font(.subheadline)
                        .foregroundStyle(StarkTheme.mutedForeground)

                    if entitlements.hasPro {
                        Label("You have Pro access", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(StarkTheme.primary)
                    }

                    if loading {
                        ProgressView("Loading plans…")
                    } else if products.isEmpty {
                        Text("Subscription products are not configured yet.")
                            .foregroundStyle(StarkTheme.mutedForeground)
                    } else {
                        ForEach(products, id: \.id) { product in
                            productCard(product)
                        }
                    }

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .background(StarkTheme.background)
            .navigationTitle("Subscription")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadProducts()
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(product.displayName)
                    .font(.headline)
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
            }
            Text(product.description)
                .font(.subheadline)
                .foregroundStyle(StarkTheme.mutedForeground)

            Button {
                Task { await purchase(product) }
            } label: {
                Group {
                    if purchasingId == product.id {
                        ProgressView()
                    } else {
                        Text("Subscribe")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchasingId != nil)
        }
        .padding(16)
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func loadProducts() async {
        loading = true
        defer { loading = false }
        do {
            try await StoreKitService.shared.loadProducts()
            products = StoreKitService.shared.products
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func purchase(_ product: Product) async {
        purchasingId = product.id
        error = nil
        defer { purchasingId = nil }
        do {
            try await entitlements.purchase(product: product)
            dismiss()
        } catch StoreKitServiceError.userCancelled {
            return
        } catch {
            self.error = error.localizedDescription
        }
    }
}
