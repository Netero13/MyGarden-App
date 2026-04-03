import Foundation
import SwiftUI

// MARK: - Weather Manager
// Fetches real weather data from the Open-Meteo API.
// Open-Meteo is completely FREE and needs NO API KEY — perfect for us.
//
// Key concepts:
// - async/await: Swift's way to handle network requests without freezing the UI.
//   "await" means "wait for this to finish, but don't block anything else."
// - JSONDecoder: converts the JSON response into Swift structs.
// - @Observable: makes SwiftUI update automatically when weather data arrives.
//
// The API returns "weather codes" (WMO standard) — numbers that represent
// weather conditions like clear (0), cloudy (1-3), rain (61-65), snow (71-75), etc.
// We convert these codes into friendly names and animation types.

// MARK: - Weather Condition
// Represents the current weather in a way our app understands.

enum WeatherCondition: String {
    case clear = "Clear"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case fog = "Fog"
    case drizzle = "Drizzle"
    case rain = "Rain"
    case heavyRain = "Heavy Rain"
    case snow = "Snow"
    case thunderstorm = "Thunderstorm"

    // Localized display name
    var localizedName: String {
        NSLocalizedString(rawValue, comment: "")
    }

    // Localized gardening tip
    var localizedTip: String {
        NSLocalizedString(gardeningTip, comment: "")
    }

    // SF Symbol icon for each condition
    var icon: String {
        switch self {
        case .clear:        return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy:       return "cloud.fill"
        case .fog:          return "cloud.fog.fill"
        case .drizzle:      return "cloud.drizzle.fill"
        case .rain:         return "cloud.rain.fill"
        case .heavyRain:    return "cloud.heavyrain.fill"
        case .snow:         return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        }
    }

    // Color theme for each condition
    var color: Color {
        switch self {
        case .clear:        return .yellow
        case .partlyCloudy: return .orange
        case .cloudy:       return .gray
        case .fog:          return .gray
        case .drizzle:      return .cyan
        case .rain:         return .blue
        case .heavyRain:    return .indigo
        case .snow:         return .white
        case .thunderstorm: return .purple
        }
    }

    // Gardening tip for each weather
    var gardeningTip: String {
        switch self {
        case .clear:        return "Great day for gardening! Check soil moisture."
        case .partlyCloudy: return "Nice weather for outdoor plants."
        case .cloudy:       return "Good day to transplant — less sun stress."
        case .fog:          return "High humidity — watch for fungal diseases."
        case .drizzle:      return "Light rain — may not be enough for deep roots."
        case .rain:         return "Nature is watering for you! Skip watering today."
        case .heavyRain:    return "Check drainage — avoid waterlogged roots."
        case .snow:         return "Protect tender plants from frost."
        case .thunderstorm: return "Keep indoors! Move potted plants to shelter."
        }
    }

    // Convert WMO weather code to our WeatherCondition
    // WMO codes: https://open-meteo.com/en/docs
    static func from(code: Int) -> WeatherCondition {
        switch code {
        case 0:         return .clear
        case 1, 2:      return .partlyCloudy
        case 3:         return .cloudy
        case 45, 48:    return .fog
        case 51, 53, 55, 56, 57: return .drizzle
        case 61, 63, 66:         return .rain
        case 65, 67:             return .heavyRain
        case 71, 73, 75, 77, 85, 86: return .snow
        case 80, 81:             return .rain
        case 82:                 return .heavyRain
        case 95, 96, 99:        return .thunderstorm
        default:                 return .partlyCloudy
        }
    }
}

// MARK: - Weather Data
// Holds all the weather info we display in the app.

struct WeatherData {
    let temperature: Double      // in Celsius
    let condition: WeatherCondition
    let humidity: Int            // percentage
    let windSpeed: Double        // km/h
    let locationName: String
}

// MARK: - Weather Manager

@Observable
class WeatherManager {

    // Singleton — one shared instance across the app
    static let shared = WeatherManager()

    // Current weather data (nil = not loaded yet)
    var currentWeather: WeatherData?

    // Loading state
    var isLoading: Bool = false

    // Error message (nil = no error)
    var errorMessage: String?

    // Location for weather — saved in UserDefaults so user can change it.
    // Defaults to Kyiv, Ukraine 🇺🇦
    var latitude: Double {
        get { UserDefaults.standard.object(forKey: "weatherLatitude") as? Double ?? 50.4501 }
        set { UserDefaults.standard.set(newValue, forKey: "weatherLatitude") }
    }

    var longitude: Double {
        get { UserDefaults.standard.object(forKey: "weatherLongitude") as? Double ?? 30.5234 }
        set { UserDefaults.standard.set(newValue, forKey: "weatherLongitude") }
    }

    var locationName: String {
        get { UserDefaults.standard.string(forKey: "weatherLocationName") ?? "Kyiv" }
        set { UserDefaults.standard.set(newValue, forKey: "weatherLocationName") }
    }

    // Cache: don't fetch more often than every 15 minutes
    private var lastFetchTime: Date?
    private let cacheMinutes: Double = 15

    private init() {}

    // MARK: - Change Location
    // Called when the user picks a different city in Settings.
    // Clears the cache so weather refreshes immediately.

    func setLocation(name: String, lat: Double, lon: Double) {
        locationName = name
        latitude = lat
        longitude = lon
        // Clear cache to force a fresh fetch
        lastFetchTime = nil
        currentWeather = nil
    }

    // MARK: - Fetch Weather
    // Calls the Open-Meteo API and parses the response.
    //
    // Key concept: async throws
    // - "async" = this function takes time (network request), don't block the UI
    // - "throws" = if something goes wrong, it throws an error instead of crashing

    func fetchWeather() async {
        // Check cache — don't spam the API
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheMinutes * 60,
           currentWeather != nil {
            return // Use cached data
        }

        isLoading = true
        errorMessage = nil

        // Build the API URL
        // Open-Meteo gives us: temperature, weather code, humidity, wind speed
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m&timezone=auto"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            // Make the network request
            // URLSession.shared.data(from:) fetches data from the internet
            let (data, _) = try await URLSession.shared.data(from: url)

            // Parse the JSON response
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            // Convert to our WeatherData model
            let weather = WeatherData(
                temperature: response.current.temperature_2m,
                condition: WeatherCondition.from(code: response.current.weather_code),
                humidity: Int(response.current.relative_humidity_2m),
                windSpeed: response.current.wind_speed_10m,
                locationName: locationName
            )

            // Update on main thread (UI updates must happen on main thread)
            await MainActor.run {
                self.currentWeather = weather
                self.lastFetchTime = Date()
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "Could not load weather"
                self.isLoading = false
            }
        }
    }
}

// MARK: - API Response Models
// These structs match the JSON structure returned by Open-Meteo.
// JSONDecoder uses these to automatically parse the response.
//
// The API returns something like:
// {
//   "current": {
//     "temperature_2m": 18.5,
//     "weather_code": 1,
//     "relative_humidity_2m": 65,
//     "wind_speed_10m": 12.3
//   }
// }

private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
}

private struct CurrentWeather: Codable {
    let temperature_2m: Double
    let weather_code: Int
    let relative_humidity_2m: Double
    let wind_speed_10m: Double
}
