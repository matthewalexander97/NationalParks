import Foundation
import Observation

enum ParkSortOrder: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: Self { self }

    var title: String {
        switch self {
        case .ascending: "A to Z"
        case .descending: "Z to A"
        }
    }
}

struct USState: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }

    static let all: [USState] = [
        USState(code: "AL", name: "Alabama"), USState(code: "AK", name: "Alaska"),
        USState(code: "AZ", name: "Arizona"), USState(code: "AR", name: "Arkansas"),
        USState(code: "CA", name: "California"), USState(code: "CO", name: "Colorado"),
        USState(code: "CT", name: "Connecticut"), USState(code: "DE", name: "Delaware"),
        USState(code: "DC", name: "District of Columbia"), USState(code: "FL", name: "Florida"),
        USState(code: "GA", name: "Georgia"), USState(code: "HI", name: "Hawaii"),
        USState(code: "ID", name: "Idaho"), USState(code: "IL", name: "Illinois"),
        USState(code: "IN", name: "Indiana"), USState(code: "IA", name: "Iowa"),
        USState(code: "KS", name: "Kansas"), USState(code: "KY", name: "Kentucky"),
        USState(code: "LA", name: "Louisiana"), USState(code: "ME", name: "Maine"),
        USState(code: "MD", name: "Maryland"), USState(code: "MA", name: "Massachusetts"),
        USState(code: "MI", name: "Michigan"), USState(code: "MN", name: "Minnesota"),
        USState(code: "MS", name: "Mississippi"), USState(code: "MO", name: "Missouri"),
        USState(code: "MT", name: "Montana"), USState(code: "NE", name: "Nebraska"),
        USState(code: "NV", name: "Nevada"), USState(code: "NH", name: "New Hampshire"),
        USState(code: "NJ", name: "New Jersey"), USState(code: "NM", name: "New Mexico"),
        USState(code: "NY", name: "New York"), USState(code: "NC", name: "North Carolina"),
        USState(code: "ND", name: "North Dakota"), USState(code: "OH", name: "Ohio"),
        USState(code: "OK", name: "Oklahoma"), USState(code: "OR", name: "Oregon"),
        USState(code: "PA", name: "Pennsylvania"), USState(code: "RI", name: "Rhode Island"),
        USState(code: "SC", name: "South Carolina"), USState(code: "SD", name: "South Dakota"),
        USState(code: "TN", name: "Tennessee"), USState(code: "TX", name: "Texas"),
        USState(code: "UT", name: "Utah"), USState(code: "VT", name: "Vermont"),
        USState(code: "VA", name: "Virginia"), USState(code: "WA", name: "Washington"),
        USState(code: "WV", name: "West Virginia"), USState(code: "WI", name: "Wisconsin"),
        USState(code: "WY", name: "Wyoming")
    ]
}

enum ParksLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

enum ParksAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(statusCode: Int)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL: "The parks request could not be created."
        case .invalidResponse: "The NPS server returned an invalid response."
        case .server(let statusCode): "The NPS server returned error \(statusCode). Check your API key and try again."
        case .missingAPIKey: "Add your NPS API key to load parks."
        }
    }
}

struct ParksAPIClient {
    func fetchParks(stateCode: String, apiKey: String) async throws -> [Park] {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParksAPIError.missingAPIKey
        }

        var components = URLComponents(string: "https://developer.nps.gov/api/v1/parks")
        components?.queryItems = [
            URLQueryItem(name: "stateCode", value: stateCode.lowercased()),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]

        guard let url = components?.url else {
            throw ParksAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ParksAPIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ParksAPIError.server(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(ParksResponse.self, from: data).data
    }
}

@MainActor
@Observable
final class ParksViewModel {
    var selectedState = USState(code: "CA", name: "California")
    var searchText = "" {
        didSet { updateVisibleParks() }
    }
    var sortOrder = ParkSortOrder.ascending {
        didSet { updateVisibleParks() }
    }
    private(set) var visibleParks: [Park] = []
    private(set) var loadState = ParksLoadState.idle

    private var parks: [Park] = [] {
        didSet { updateVisibleParks() }
    }
    private let apiClient = ParksAPIClient()

    func fetchParks(apiKey: String) async {
        loadState = .loading

        do {
            parks = try await apiClient.fetchParks(
                stateCode: selectedState.code,
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            parks = []
            loadState = .failed(error.localizedDescription)
        }
    }

    private func updateVisibleParks() {
        visibleParks = parks.filtered(by: searchText, sortOrder: sortOrder)
    }
}

extension Collection where Element == Park {
    func filtered(by searchText: String, sortOrder: ParkSortOrder) -> [Park] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingParks = trimmedSearchText.isEmpty ? Array(self) : filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearchText)
                || $0.fullName.localizedCaseInsensitiveContains(trimmedSearchText)
        }

        return matchingParks.sorted {
            switch sortOrder {
            case .ascending:
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            case .descending:
                $0.name.localizedStandardCompare($1.name) == .orderedDescending
            }
        }
    }
}
