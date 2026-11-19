import Foundation

struct ParksResponse: Decodable {
    let data: [Park]
}

struct Park: Codable, Identifiable, Hashable {
    let id: String
    let fullName: String
    let description: String
    let latitude: String
    let longitude: String
    let images: [ParkImage]
    let name: String

    static func == (lhs: Park, rhs: Park) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ParkImage: Codable, Identifiable, Hashable {
    let title: String
    let caption: String
    let url: String

    var id: String { url }
}

extension Park {
    static let preview = Park(
        id: "yose",
        fullName: "Yosemite National Park",
        description: "Not just a great valley, but a shrine to human foresight and the strength of granite.",
        latitude: "37.84883288",
        longitude: "-119.5571873",
        images: [],
        name: "Yosemite"
    )
}
