import Foundation
import Testing
@testable import Park_Explorer

@MainActor
struct ParkExplorerTests {
    @Test
    func decodesParksResponse() throws {
        let json = """
        {
          "data": [
            {
              "id": "acad",
              "fullName": "Acadia National Park",
              "description": "A park on the Atlantic coast.",
              "latitude": "44.409286",
              "longitude": "-68.247501",
              "images": [
                {
                  "title": "Coastline",
                  "caption": "Rocky coastline at sunrise.",
                  "url": "https://example.com/acadia.jpg"
                }
              ],
              "name": "Acadia"
            }
          ]
        }
        """

        let response = try JSONDecoder().decode(
            ParksResponse.self,
            from: Data(json.utf8)
        )

        #expect(response.data.count == 1)
        #expect(response.data.first?.name == "Acadia")
        #expect(response.data.first?.images.first?.title == "Coastline")
    }

    @Test
    func filtersByShortOrFullName() {
        let parks = [
            makePark(name: "Yosemite", fullName: "Yosemite National Park"),
            makePark(name: "Golden Gate", fullName: "Golden Gate National Recreation Area")
        ]

        #expect(parks.filtered(by: "recreation", sortOrder: .ascending).map(\.name) == ["Golden Gate"])
        #expect(parks.filtered(by: "YOSEMITE", sortOrder: .ascending).map(\.name) == ["Yosemite"])
    }

    @Test
    func sortsParksInBothDirections() {
        let parks = [
            makePark(name: "Zion", fullName: "Zion National Park"),
            makePark(name: "Acadia", fullName: "Acadia National Park")
        ]

        #expect(parks.filtered(by: "", sortOrder: .ascending).map(\.name) == ["Acadia", "Zion"])
        #expect(parks.filtered(by: "", sortOrder: .descending).map(\.name) == ["Zion", "Acadia"])
    }

    private func makePark(name: String, fullName: String) -> Park {
        Park(
            id: name,
            fullName: fullName,
            description: "Description",
            latitude: "0",
            longitude: "0",
            images: [],
            name: name
        )
    }
}
