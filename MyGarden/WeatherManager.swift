import Foundation
import SwiftUI

// MARK: - Weather Manager
// Fetches real weather data from the Open-Meteo API.
// Open-Meteo is completely FREE and needs NO API KEY — perfect for us.
//
// Phase 2 upgrade: now fetches EXTENDED data including:
// - Current conditions (temp, humidity, wind, rain)
// - Today's precipitation total
// - Today's min/max temperature
// - Next 3 days forecast (for frost warnings, rain predictions)
//
// This data powers the "Weather Intelligence" feature — smart alerts
// like "Skip watering, it rained 8mm" or "Frost tonight, protect trees".

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
// Holds all the weather info we display and use for smart recommendations.

struct WeatherData {
    let temperature: Double          // current temperature in Celsius
    let condition: WeatherCondition
    let humidity: Int                // percentage (0-100)
    let windSpeed: Double            // km/h
    let locationName: String

    // -- Phase 2: Extended data for smart recommendations --
    var todayRainMM: Double = 0        // total precipitation today in mm
    var todayMinTemp: Double = 0       // today's minimum temperature
    var todayMaxTemp: Double = 0       // today's maximum temperature

    // Next 3 days forecast (for advance warnings)
    var forecast: [DayForecast] = []
}

// MARK: - Day Forecast
// A simple forecast for one future day.
// Used for frost warnings and rain predictions.

struct DayForecast {
    let date: Date
    let minTemp: Double              // minimum temperature in °C
    let maxTemp: Double              // maximum temperature in °C
    let rainMM: Double               // expected precipitation in mm
    let condition: WeatherCondition  // overall weather condition
}

// MARK: - Weather Intelligence
// The "brain" that generates smart, plant-specific recommendations
// based on weather data + plant species + plant age.
//
// This is what makes Phase 2 special — connecting weather to care.

struct WeatherIntelligence {

    // MARK: - Generate Smart Tips for a Plant
    // Returns an array of weather-based tips specific to THIS plant.
    // Example: "Skip watering your Cherry — it rained 8mm today"

    static func tips(for plant: Plant, weather: WeatherData) -> [WeatherTip] {
        var tips: [WeatherTip] = []

        // Look up species intelligence (if available)
        let species = TreeEncyclopedia.find(name: plant.name)
        let intel = species?.resolvedIntelligence(forVariety: plant.variety)
        let age = plant.age
        let isYoung = age < (intel?.yearsToMature ?? 3)

        // ── Rain Tips ──────────────────────────────────────
        if weather.todayRainMM >= 5 {
            // Heavy rain — definitely skip watering
            tips.append(WeatherTip(
                icon: "cloud.rain.fill",
                color: .blue,
                title: NSLocalizedString("Skip watering today", comment: ""),
                message: String(format: NSLocalizedString("It rained %.0f mm today — your %@ has enough water.", comment: ""),
                                weather.todayRainMM, plant.displayName),
                priority: .high
            ))
        } else if weather.todayRainMM >= 2 {
            // Light rain — maybe reduce watering
            tips.append(WeatherTip(
                icon: "cloud.drizzle.fill",
                color: .cyan,
                title: NSLocalizedString("Light rain today", comment: ""),
                message: String(format: NSLocalizedString("%.0f mm of rain — may not be enough for deep roots. Check soil before watering.", comment: ""),
                                weather.todayRainMM),
                priority: .medium
            ))
        }

        // Rain coming tomorrow?
        if let tomorrow = weather.forecast.first, tomorrow.rainMM >= 5 {
            tips.append(WeatherTip(
                icon: "cloud.rain.fill",
                color: .blue,
                title: NSLocalizedString("Rain expected tomorrow", comment: ""),
                message: String(format: NSLocalizedString("%.0f mm expected — you can delay watering.", comment: ""),
                                tomorrow.rainMM),
                priority: .medium
            ))
        }

        // ── Frost Tips ─────────────────────────────────────
        let frostHardiness = intel?.frostHardiness ?? -10

        // Frost TONIGHT (today's min temp)
        if weather.todayMinTemp <= 0 {
            if weather.todayMinTemp <= Double(frostHardiness) {
                // Dangerous frost — below species tolerance
                tips.append(WeatherTip(
                    icon: "thermometer.snowflake",
                    color: .red,
                    title: NSLocalizedString("Dangerous frost!", comment: ""),
                    message: String(format: NSLocalizedString("Tonight drops to %.0f°C — below %@'s tolerance of %lld°C. Protect immediately!", comment: ""),
                                    weather.todayMinTemp, plant.displayName, frostHardiness),
                    priority: .urgent
                ))
            } else {
                // Light frost — within tolerance but young trees are more at risk
                tips.append(WeatherTip(
                    icon: "thermometer.snowflake",
                    color: isYoung ? .red : .cyan,
                    title: NSLocalizedString("Frost tonight", comment: ""),
                    message: String(format: NSLocalizedString("%.0f°C expected. Your %@ can handle it, but young branches may be at risk.", comment: ""),
                                    weather.todayMinTemp, plant.displayName),
                    priority: isYoung ? .urgent : .high
                ))
            }
        }

        // Frost in forecast (next 2-3 days)
        for day in weather.forecast.dropFirst().prefix(2) {
            if day.minTemp <= 0 {
                let dayName = Self.dayName(for: day.date)
                tips.append(WeatherTip(
                    icon: "snowflake",
                    color: .cyan,
                    title: String(format: NSLocalizedString("Frost on %@", comment: ""), dayName),
                    message: String(format: NSLocalizedString("%.0f°C expected. Prepare protection for %@.", comment: ""),
                                    day.minTemp, plant.displayName),
                    priority: .medium
                ))
                break // Only show one frost forecast warning
            }
        }

        // ── Heat Tips ──────────────────────────────────────
        if weather.todayMaxTemp >= 35 {
            tips.append(WeatherTip(
                icon: "sun.max.trianglebadge.exclamationmark.fill",
                color: .red,
                title: NSLocalizedString("Extreme heat!", comment: ""),
                message: String(format: NSLocalizedString("%.0f°C today — water %@ in the evening, not midday. Mulch to keep roots cool.", comment: ""),
                                weather.todayMaxTemp, plant.displayName),
                priority: .high
            ))
        } else if weather.todayMaxTemp >= 30 {
            tips.append(WeatherTip(
                icon: "sun.max.fill",
                color: isYoung ? .red : .orange,
                title: NSLocalizedString("Hot day", comment: ""),
                message: isYoung
                    ? String(format: NSLocalizedString("%.0f°C — your young %@ needs extra water in this heat!", comment: ""),
                             weather.todayMaxTemp, plant.displayName)
                    : String(format: NSLocalizedString("%.0f°C — consider extra watering for %@, especially if young.", comment: ""),
                             weather.todayMaxTemp, plant.displayName),
                priority: isYoung ? .high : .medium
            ))
        }

        // ── Humidity Tips ──────────────────────────────────
        if weather.humidity >= 85 && weather.temperature >= 20 {
            // High humidity + warm = fungal risk
            if let diseases = intel?.commonDiseases, !diseases.isEmpty {
                tips.append(WeatherTip(
                    icon: "humidity.fill",
                    color: .green,
                    title: NSLocalizedString("Fungal risk", comment: ""),
                    message: String(format: NSLocalizedString("High humidity (%lld%%) + warmth — watch %@ for %@.", comment: ""),
                                    weather.humidity, plant.displayName, diseases.first ?? "disease"),
                    priority: .medium
                ))
            }
        }

        // ── Wind Tips ──────────────────────────────────────
        // Young trees are especially vulnerable — lower threshold
        let windThreshold: Double = isYoung ? 35 : 50
        if weather.windSpeed >= windThreshold {
            tips.append(WeatherTip(
                icon: "wind",
                color: isYoung ? .orange : .gray,
                title: NSLocalizedString("Strong wind!", comment: ""),
                message: String(format: NSLocalizedString("Wind at %.0f km/h — stake young %@ and check supports.", comment: ""),
                                weather.windSpeed, plant.displayName),
                priority: isYoung ? .urgent : .high
            ))
        }

        // Sort by priority (urgent first)
        tips.sort { $0.priority.rawValue > $1.priority.rawValue }

        return tips
    }

    // MARK: - Watering Adjustment
    // Returns a recommendation: skip, reduce, normal, or increase watering.

    static func wateringAdjustment(for plant: Plant, weather: WeatherData) -> WateringAdjustment {
        let species = TreeEncyclopedia.find(name: plant.name)
        let intel = species?.resolvedIntelligence(forVariety: plant.variety)
        let isYoung = plant.age < (intel?.yearsToMature ?? 3)

        // Heavy rain today → skip
        if weather.todayRainMM >= 5 {
            return .skip
        }

        // Rain tomorrow → can delay
        if let tomorrow = weather.forecast.first, tomorrow.rainMM >= 5 {
            return .delay
        }

        // Light rain → reduce
        if weather.todayRainMM >= 2 {
            return .reduce
        }

        // Extreme heat → increase (young trees need even more)
        if weather.todayMaxTemp >= 35 {
            return .increase
        }

        // Hot day → young trees need more water, established ones can manage
        if weather.todayMaxTemp >= 30 {
            return isYoung ? .increase : .slightlyMore
        }

        // Warm day → young trees might need a bit more
        if weather.todayMaxTemp >= 27 && isYoung {
            return .slightlyMore
        }

        // Normal conditions
        return .normal
    }

    // MARK: - Day Name Helper

    private static func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        return formatter.string(from: date)
    }
}

// MARK: - Weather Tip
// A single smart recommendation with priority level.

struct WeatherTip: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let message: String
    let priority: TipPriority
}

enum TipPriority: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3

    static func < (lhs: TipPriority, rhs: TipPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Watering Adjustment
// Simple recommendation for today's watering.

enum WateringAdjustment {
    case skip        // don't water today (heavy rain)
    case delay       // rain coming tomorrow, can wait
    case reduce      // light rain, water less
    case normal      // water as usual
    case slightlyMore // warm day, maybe a bit extra
    case increase    // extreme heat, water more

    var icon: String {
        switch self {
        case .skip:          return "xmark.circle.fill"
        case .delay:         return "clock.arrow.circlepath"
        case .reduce:        return "arrow.down.circle.fill"
        case .normal:        return "checkmark.circle.fill"
        case .slightlyMore:  return "arrow.up.circle.fill"
        case .increase:      return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .skip:          return .blue
        case .delay:         return .cyan
        case .reduce:        return .teal
        case .normal:        return .green
        case .slightlyMore:  return .orange
        case .increase:      return .red
        }
    }

    var localizedLabel: String {
        switch self {
        case .skip:          return NSLocalizedString("Skip watering", comment: "")
        case .delay:         return NSLocalizedString("Can delay", comment: "")
        case .reduce:        return NSLocalizedString("Water less", comment: "")
        case .normal:        return NSLocalizedString("Water normally", comment: "")
        case .slightlyMore:  return NSLocalizedString("Water a bit more", comment: "")
        case .increase:      return NSLocalizedString("Water extra!", comment: "")
        }
    }
}

// MARK: - Weather Manager

@Observable
class WeatherManager {

    // Singleton
    static let shared = WeatherManager()

    // Current weather data (nil = not loaded yet)
    var currentWeather: WeatherData?

    // Loading state
    var isLoading: Bool = false

    // Error message (nil = no error)
    var errorMessage: String?

    // Location for weather — saved in UserDefaults.
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

    func setLocation(name: String, lat: Double, lon: Double) {
        locationName = name
        latitude = lat
        longitude = lon
        lastFetchTime = nil
        currentWeather = nil
    }

    // MARK: - Fetch Weather (Extended)
    // Now fetches current conditions + today's daily data + 3-day forecast.

    func fetchWeather() async {
        // Check cache
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheMinutes * 60,
           currentWeather != nil {
            return
        }

        isLoading = true
        errorMessage = nil

        // Extended API call: current + daily forecast for 4 days (today + 3)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,precipitation&daily=temperature_2m_min,temperature_2m_max,precipitation_sum,weather_code&forecast_days=4&timezone=auto"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            // Parse daily forecasts
            var forecasts: [DayForecast] = []
            let dailyDates = response.daily.time
            for i in 1..<min(dailyDates.count, 4) { // Skip today (index 0), take next 3
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: dailyDates[i]) ?? Date()

                forecasts.append(DayForecast(
                    date: date,
                    minTemp: response.daily.temperature_2m_min[i],
                    maxTemp: response.daily.temperature_2m_max[i],
                    rainMM: response.daily.precipitation_sum[i],
                    condition: WeatherCondition.from(code: response.daily.weather_code[i])
                ))
            }

            // Today's daily data (index 0)
            let todayRain = (response.daily.precipitation_sum.first ?? 0) + (response.current.precipitation ?? 0)
            let todayMin = response.daily.temperature_2m_min.first ?? response.current.temperature_2m
            let todayMax = response.daily.temperature_2m_max.first ?? response.current.temperature_2m

            let weather = WeatherData(
                temperature: response.current.temperature_2m,
                condition: WeatherCondition.from(code: response.current.weather_code),
                humidity: Int(response.current.relative_humidity_2m),
                windSpeed: response.current.wind_speed_10m,
                locationName: locationName,
                todayRainMM: todayRain,
                todayMinTemp: todayMin,
                todayMaxTemp: todayMax,
                forecast: forecasts
            )

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
// Extended to include daily forecast data.

private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
}

private struct CurrentWeather: Codable {
    let temperature_2m: Double
    let weather_code: Int
    let relative_humidity_2m: Double
    let wind_speed_10m: Double
    let precipitation: Double?  // current precipitation in mm (may be null)
}

private struct DailyWeather: Codable {
    let time: [String]                    // dates as "2026-04-04"
    let temperature_2m_min: [Double]      // daily min temps
    let temperature_2m_max: [Double]      // daily max temps
    let precipitation_sum: [Double]       // daily total rain in mm
    let weather_code: [Int]               // daily weather codes
}
