import Foundation
import CoreLocation

// MARK: - Location Manager
// Handles getting the user's GPS location for weather data.
//
// Key concepts:
// - CLLocationManager: Apple's built-in GPS manager
// - CLLocationManagerDelegate: a "callback" pattern where iOS tells US when
//   location data is ready (instead of us asking repeatedly)
// - Authorization: iOS requires the user to EXPLICITLY allow location access.
//   We ask nicely with a popup, and they can say yes or no.
//
// Flow:
// 1. App asks: "Can I use your location for weather?"
// 2. User sees iOS popup → taps Allow or Don't Allow
// 3. If allowed, we get GPS coordinates → send to WeatherManager
// 4. If denied, we fall back to manual city picker
//
// We only need location ONCE (not continuously), so we use
// requestLocation() instead of startUpdatingLocation().

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {

    // Singleton — one shared instance across the app
    static let shared = LocationManager()

    // The actual Apple location manager that talks to GPS hardware
    private let manager = CLLocationManager()

    // Current authorization status
    // This tells us if the user said "yes", "no", or hasn't been asked yet
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // Whether we're currently fetching location
    var isLocating: Bool = false

    // The user's coordinates (nil = not determined yet)
    var lastLocation: CLLocation?

    // Error message if something goes wrong
    var errorMessage: String?

    // Whether user has been asked for location permission
    // We save this to UserDefaults so we only ask ONCE
    var hasBeenAsked: Bool {
        get { UserDefaults.standard.bool(forKey: "locationPermissionAsked") }
        set { UserDefaults.standard.set(newValue, forKey: "locationPermissionAsked") }
    }

    // Whether user chose to use GPS for weather (vs manual city)
    var useGPSForWeather: Bool {
        get { UserDefaults.standard.object(forKey: "useGPSForWeather") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "useGPSForWeather") }
    }

    // MARK: - Init

    private override init() {
        super.init()
        // Set ourselves as the delegate — iOS will call our methods when location changes
        manager.delegate = self
        // We only need approximate location (city-level) for weather
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        // Read current status
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Request Permission
    // Shows the iOS popup: "MyGarden would like to use your location"
    // The user sees our custom message (set in project settings).

    func requestPermission() {
        hasBeenAsked = true
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Get Current Location
    // Asks the GPS for ONE location fix, then stops.
    // Much more battery-friendly than continuous tracking.

    func requestLocation() {
        isLocating = true
        errorMessage = nil
        manager.requestLocation()
    }

    // MARK: - Check if we CAN use location
    // Returns true if the user has allowed location access.

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse ||
        authorizationStatus == .authorizedAlways
    }

    // MARK: - CLLocationManagerDelegate Methods
    // These are "callbacks" — iOS calls these automatically when:
    // 1. The user responds to the permission popup
    // 2. Location data is ready
    // 3. Something goes wrong

    // Called when authorization status changes (user tapped Allow/Don't Allow)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // If user just allowed, and we want GPS weather, fetch location immediately
        if isAuthorized && useGPSForWeather {
            requestLocation()
        }
    }

    // Called when GPS successfully gets a location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLocating = false

        // Take the most recent location
        guard let location = locations.last else { return }
        lastLocation = location

        // Update WeatherManager with GPS coordinates
        // We use reverse geocoding to get the city name from coordinates
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            // Get city name from GPS (or use "My Location" as fallback)
            let cityName = placemarks?.first?.locality ?? "My Location"

            // Tell WeatherManager to use these coordinates
            WeatherManager.shared.setLocation(
                name: cityName,
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            )

            // Fetch weather with the new coordinates
            Task {
                await WeatherManager.shared.fetchWeather()
            }
        }
    }

    // Called when GPS fails
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        errorMessage = "Could not determine location"
        print("Location error: \(error.localizedDescription)")
    }
}
