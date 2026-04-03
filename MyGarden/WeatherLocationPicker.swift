import SwiftUI

// MARK: - Weather Location Picker
// Lets the user pick their city for weather data.
// Shows a list of Ukrainian cities + other popular cities.
// The user can also search by name.
//
// Why a preset list instead of free text?
// Because we need exact coordinates (latitude/longitude) for the API.
// A preset list guarantees correct coordinates without needing a geocoding API.

struct WeatherLocationPicker: View {

    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""

    var body: some View {
        List {
            // Current selection
            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(WeatherManager.shared.locationName)
                        .fontWeight(.medium)
                    Spacer()
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Ukrainian cities
            Section {
                ForEach(filteredCities.filter { $0.country == "Ukraine" }) { city in
                    cityRow(city)
                }
            } header: {
                Label("Ukraine", systemImage: "flag.fill")
            }

            // Other cities
            Section {
                ForEach(filteredCities.filter { $0.country != "Ukraine" }) { city in
                    cityRow(city)
                }
            } header: {
                Label("Other", systemImage: "globe")
            }
        }
        .navigationTitle("Weather Location")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search city...")
    }

    private func cityRow(_ city: CityLocation) -> some View {
        Button {
            WeatherManager.shared.setLocation(
                name: city.name,
                lat: city.latitude,
                lon: city.longitude
            )
            // Fetch weather for new location
            Task {
                await WeatherManager.shared.fetchWeather()
            }
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .foregroundStyle(.primary)
                    Text(city.country)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if WeatherManager.shared.locationName == city.name {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var filteredCities: [CityLocation] {
        if searchText.isEmpty {
            return CityLocation.all
        }
        return CityLocation.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - City Location
// Preset cities with coordinates. Heavy focus on Ukrainian cities
// since this is a Ukrainian app, plus a few international ones.

struct CityLocation: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double

    static let all: [CityLocation] = [
        // Ukrainian cities (major + regional centers)
        CityLocation(name: "Kyiv", country: "Ukraine", latitude: 50.4501, longitude: 30.5234),
        CityLocation(name: "Kharkiv", country: "Ukraine", latitude: 49.9935, longitude: 36.2304),
        CityLocation(name: "Odesa", country: "Ukraine", latitude: 46.4825, longitude: 30.7233),
        CityLocation(name: "Dnipro", country: "Ukraine", latitude: 48.4647, longitude: 35.0462),
        CityLocation(name: "Lviv", country: "Ukraine", latitude: 49.8397, longitude: 24.0297),
        CityLocation(name: "Zaporizhzhia", country: "Ukraine", latitude: 47.8388, longitude: 35.1396),
        CityLocation(name: "Vinnytsia", country: "Ukraine", latitude: 49.2331, longitude: 28.4682),
        CityLocation(name: "Poltava", country: "Ukraine", latitude: 49.5883, longitude: 34.5514),
        CityLocation(name: "Chernihiv", country: "Ukraine", latitude: 51.4982, longitude: 31.2893),
        CityLocation(name: "Cherkasy", country: "Ukraine", latitude: 49.4444, longitude: 32.0598),
        CityLocation(name: "Zhytomyr", country: "Ukraine", latitude: 50.2547, longitude: 28.6587),
        CityLocation(name: "Sumy", country: "Ukraine", latitude: 50.9077, longitude: 34.7981),
        CityLocation(name: "Rivne", country: "Ukraine", latitude: 50.6199, longitude: 26.2516),
        CityLocation(name: "Ivano-Frankivsk", country: "Ukraine", latitude: 48.9226, longitude: 24.7111),
        CityLocation(name: "Ternopil", country: "Ukraine", latitude: 49.5535, longitude: 25.5948),
        CityLocation(name: "Lutsk", country: "Ukraine", latitude: 50.7472, longitude: 25.3254),
        CityLocation(name: "Uzhhorod", country: "Ukraine", latitude: 48.6208, longitude: 22.2879),
        CityLocation(name: "Khmelnytskyi", country: "Ukraine", latitude: 49.4230, longitude: 26.9871),
        CityLocation(name: "Chernivtsi", country: "Ukraine", latitude: 48.2920, longitude: 25.9358),
        CityLocation(name: "Kropyvnytskyi", country: "Ukraine", latitude: 48.5079, longitude: 32.2623),
        CityLocation(name: "Mykolaiv", country: "Ukraine", latitude: 46.9750, longitude: 31.9946),

        // International
        CityLocation(name: "Warsaw", country: "Poland", latitude: 52.2297, longitude: 21.0122),
        CityLocation(name: "Berlin", country: "Germany", latitude: 52.5200, longitude: 13.4050),
        CityLocation(name: "London", country: "UK", latitude: 51.5074, longitude: -0.1278),
        CityLocation(name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522),
        CityLocation(name: "Prague", country: "Czech Republic", latitude: 50.0755, longitude: 14.4378),
        CityLocation(name: "Bucharest", country: "Romania", latitude: 44.4268, longitude: 26.1025),
        CityLocation(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784),
        CityLocation(name: "New York", country: "USA", latitude: 40.7128, longitude: -74.0060),
        CityLocation(name: "Toronto", country: "Canada", latitude: 43.6532, longitude: -79.3832),
    ]
}

#Preview {
    NavigationStack {
        WeatherLocationPicker()
    }
}
