import SwiftUI

struct ContentView: View {
    @State private var apiKey = KeychainStore.loadAPIKey() ?? ""
    @State private var model = ParksViewModel()
    @State private var isShowingAPIKey = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ParksContent(
                parks: model.visibleParks,
                loadState: model.loadState,
                hasAPIKey: !apiKey.isEmpty
            )
            .navigationDestination(for: Park.self) { park in
                ParkDetailView(park: park)
            }
            .navigationTitle("Park Explorer")
            .searchable(text: $model.searchText, prompt: "Search parks")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Picker("State", selection: $model.selectedState) {
                            ForEach(USState.all) { state in
                                Text(state.name).tag(state)
                            }
                        }
                    } label: {
                        Label(model.selectedState.code, systemImage: "map")
                    }
                    .accessibilityLabel("Select state")
                }

                ToolbarItemGroup(placement: .automatic) {
                    Menu {
                        Picker("Sort order", selection: $model.sortOrder) {
                            ForEach(ParkSortOrder.allCases) { order in
                                Text(order.title).tag(order)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }

                    Button {
                        isShowingAPIKey = true
                    } label: {
                        Label("API Key", systemImage: "key")
                    }
                }
            }
            .task(id: FetchRequest(state: model.selectedState, apiKey: apiKey)) {
                guard !apiKey.isEmpty else { return }
                await model.fetchParks(apiKey: apiKey)
            }
            .refreshable {
                await model.fetchParks(apiKey: apiKey)
            }
            .sheet(isPresented: $isShowingAPIKey) {
                APIKeyView(apiKey: apiKey) { newAPIKey in
                    try KeychainStore.saveAPIKey(newAPIKey)
                    apiKey = newAPIKey
                }
            }
            .safeAreaInset(edge: .bottom) {
                AuthorFooter()
            }
        }
    }
}

private struct FetchRequest: Equatable {
    let state: USState
    let apiKey: String
}

private struct ParksContent: View {
    let parks: [Park]
    let loadState: ParksLoadState
    let hasAPIKey: Bool

    var body: some View {
        if !hasAPIKey {
            ContentUnavailableView {
                Label("NPS API Key Needed", systemImage: "key")
            } description: {
                Text("Tap the key button, then paste the API key emailed to you by the National Park Service.")
            }
        } else if loadState == .loading && parks.isEmpty {
            ProgressView("Loading parks…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if case .failed(let message) = loadState {
            ContentUnavailableView(
                "Unable to Load Parks",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
        } else if parks.isEmpty {
            ContentUnavailableView.search
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(parks) { park in
                        NavigationLink(value: park) {
                            ParkRow(
                                name: park.name,
                                imageURL: park.images.first.flatMap { URL(string: $0.url) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

private struct ParkRow: View {
    let name: String
    let imageURL: URL?

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.secondary.opacity(0.15)
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                ZStack {
                    Color.secondary.opacity(0.15)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            @unknown default:
                Color.secondary.opacity(0.15)
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .overlay(alignment: .bottomLeading) {
            Text(name)
                .font(.title)
                .bold()
                .foregroundStyle(.white)
                .shadow(radius: 3)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityHint("Opens park details")
    }
}

private struct APIKeyView: View {
    @State private var apiKey: String
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    let save: (String) throws -> Void

    init(apiKey: String, save: @escaping (String) throws -> Void) {
        _apiKey = State(initialValue: apiKey)
        self.save = save
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("NPS API key", text: $apiKey)
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Request a free key at developer.nps.gov. Your key is protected in this device's Keychain.")
                }
            }
            .navigationTitle("NPS Setup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        do {
                            try save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        } catch {
                            errorMessage = "The API key could not be saved. Please try again."
                        }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Unable to Save API Key", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.medium])
    }
}

private struct AuthorFooter: View {
    var body: some View {
        Text("Park data provided by the National Park Service")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.regularMaterial)
    }
}


#Preview {
    ContentView()
}
