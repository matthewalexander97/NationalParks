import MapKit
import SwiftUI

struct ParkDetailView: View {
    let park: Park

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ParkInformationSection(
                    fullName: park.fullName,
                    description: park.description
                )
                ParkImageGallery(images: park.images)
                ParkMapSection(
                    name: park.name,
                    latitude: park.latitude,
                    longitude: park.longitude
                )
                Text("Park information and photography provided by the National Park Service.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

private struct ParkInformationSection: View {
    let fullName: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fullName)
                .font(.largeTitle)
                .bold()
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

private struct ParkImageGallery: View {
    let images: [ParkImage]

    var body: some View {
        if images.isEmpty {
            ContentUnavailableView(
                "No Photos",
                systemImage: "photo",
                description: Text("The National Park Service has not provided photos for this park.")
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(images) { parkImage in
                        ParkGalleryImage(image: parkImage)
                            .containerRelativeFrame(.horizontal, count: 9, span: 8, spacing: 16)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
    }
}

private struct ParkGalleryImage: View {
    let image: ParkImage

    var body: some View {
        AsyncImage(url: URL(string: image.url)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.secondary.opacity(0.15)
                    ProgressView()
                }
            case .success(let loadedImage):
                loadedImage
                    .resizable()
                    .scaledToFill()
            case .failure:
                ContentUnavailableView("Photo Unavailable", systemImage: "photo.badge.exclamationmark")
                    .background(Color.secondary.opacity(0.15))
            @unknown default:
                Color.secondary.opacity(0.15)
            }
        }
        .aspectRatio(7 / 5, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .bottomLeading) {
            if !image.title.isEmpty || !image.caption.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !image.title.isEmpty {
                        Text(image.title)
                            .font(.headline)
                    }
                    if !image.caption.isEmpty {
                        Text(image.caption)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.65))
            }
        }
        .accessibilityLabel(image.title.isEmpty ? "Park photo" : image.title)
    }
}

private struct ParkMapSection: View {
    let name: String
    let latitude: String
    let longitude: String

    var body: some View {
        if let latitudeValue = Double(latitude),
           let longitudeValue = Double(longitude) {
            let coordinate = CLLocationCoordinate2D(
                latitude: latitudeValue,
                longitude: longitudeValue
            )

            Map(initialPosition: .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1_000_000,
                longitudinalMeters: 1_000_000
            ))) {
                Marker(name, coordinate: coordinate)
                    .tint(.purple)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .accessibilityLabel("Map showing the location of \(name)")
        }
    }
}

#Preview {
    NavigationStack {
        ParkDetailView(park: .preview)
    }
}
