import SwiftUI

// MARK: - Weather Animation View
// Displays animated weather effects based on the current condition.
// This goes behind the dashboard header to make it look alive.
//
// Each weather type has its own animation:
// - Clear: rotating sun rays + warm gradient
// - Cloudy: floating clouds drifting across
// - Rain: falling blue droplets
// - Snow: falling white snowflakes
// - Thunderstorm: rain + lightning flashes
//
// Key concepts:
// - @State + .onAppear: start animations when the view appears
// - withAnimation(.repeatForever): creates infinite looping animations
// - .offset: moves views around (used for falling rain, drifting clouds)
// - .rotationEffect: spins a view (used for sun rays)
// - TimelineView: creates frame-by-frame animations for particle effects

struct WeatherAnimationView: View {

    let condition: WeatherCondition

    var body: some View {
        ZStack {
            // Background gradient based on weather
            backgroundGradient

            // Animated particles/effects
            switch condition {
            case .clear:
                SunAnimation()
            case .partlyCloudy:
                SunAnimation(subtle: true)
                CloudsAnimation(count: 2)
            case .cloudy:
                CloudsAnimation(count: 4)
            case .fog:
                FogAnimation()
            case .drizzle:
                RainAnimation(intensity: .light)
            case .rain:
                RainAnimation(intensity: .medium)
                CloudsAnimation(count: 2, dark: true)
            case .heavyRain:
                RainAnimation(intensity: .heavy)
                CloudsAnimation(count: 3, dark: true)
            case .snow:
                SnowAnimation()
            case .thunderstorm:
                RainAnimation(intensity: .heavy)
                LightningAnimation()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // Background gradient matching the weather mood
    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gradientColors: [Color] {
        switch condition {
        case .clear:
            return [Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.1, green: 0.5, blue: 0.9)]
        case .partlyCloudy:
            return [Color(red: 0.4, green: 0.7, blue: 0.95), Color(red: 0.3, green: 0.55, blue: 0.8)]
        case .cloudy:
            return [Color(red: 0.5, green: 0.55, blue: 0.6), Color(red: 0.4, green: 0.45, blue: 0.5)]
        case .fog:
            return [Color(red: 0.6, green: 0.63, blue: 0.65), Color(red: 0.5, green: 0.53, blue: 0.55)]
        case .drizzle:
            return [Color(red: 0.4, green: 0.5, blue: 0.65), Color(red: 0.3, green: 0.4, blue: 0.55)]
        case .rain:
            return [Color(red: 0.25, green: 0.35, blue: 0.55), Color(red: 0.2, green: 0.28, blue: 0.45)]
        case .heavyRain:
            return [Color(red: 0.18, green: 0.25, blue: 0.4), Color(red: 0.12, green: 0.18, blue: 0.3)]
        case .snow:
            return [Color(red: 0.7, green: 0.75, blue: 0.85), Color(red: 0.55, green: 0.6, blue: 0.7)]
        case .thunderstorm:
            return [Color(red: 0.15, green: 0.18, blue: 0.3), Color(red: 0.1, green: 0.12, blue: 0.22)]
        }
    }
}

// MARK: - Sun Animation
// A glowing sun with rotating rays. For clear and partly cloudy weather.
//
// How it works:
// - A yellow circle (the sun)
// - A larger circle with dashed stroke = the rays
// - .rotationEffect spins the rays continuously

struct SunAnimation: View {
    var subtle: Bool = false

    @State private var rotation: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sun glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow.opacity(subtle ? 0.2 : 0.4), .clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .scaleEffect(pulse ? 1.1 : 0.95)

                // Rotating rays
                Circle()
                    .strokeBorder(
                        .yellow.opacity(subtle ? 0.15 : 0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [4, 8])
                    )
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .rotationEffect(.degrees(rotation))

                // Inner rays (faster rotation)
                Circle()
                    .strokeBorder(
                        .orange.opacity(subtle ? 0.1 : 0.2),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 6])
                    )
                    .frame(width: geo.size.width * 0.35, height: geo.size.width * 0.35)
                    .rotationEffect(.degrees(-rotation * 0.7))

                // Sun core
                Circle()
                    .fill(.yellow.opacity(subtle ? 0.25 : 0.5))
                    .frame(width: 20, height: 20)
            }
            .position(x: geo.size.width * 0.82, y: geo.size.height * 0.3)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 3).repeatForever()) {
                pulse = true
            }
        }
    }
}

// MARK: - Clouds Animation
// Floating clouds that drift across the view.
// Each cloud is an SF Symbol at a random position, slowly moving right.

struct CloudsAnimation: View {
    var count: Int = 3
    var dark: Bool = false

    @State private var offsets: [CGFloat] = []

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                let yPos = CGFloat(i) * (geo.size.height / CGFloat(count + 1)) + 10
                let size: CGFloat = CGFloat([18, 22, 16, 20][i % 4])

                Image(systemName: "cloud.fill")
                    .font(.system(size: size))
                    .foregroundStyle(.white.opacity(dark ? 0.3 : 0.5))
                    .offset(x: offsets.count > i ? offsets[i] : 0)
                    .position(x: 0, y: yPos)
            }
        }
        .onAppear {
            // Initialize at random starting positions
            offsets = (0..<count).map { _ in CGFloat.random(in: 20...200) }

            // Animate each cloud at a different speed
            for i in 0..<count {
                let duration = Double.random(in: 8...15)
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    offsets[i] = CGFloat.random(in: 150...350)
                }
            }
        }
    }
}

// MARK: - Rain Animation
// Falling rain drops using TimelineView for smooth frame-by-frame animation.
//
// Key concept: TimelineView
// Unlike .onAppear animations, TimelineView redraws every frame (~60fps).
// This lets us move MANY particles smoothly — perfect for rain/snow.

enum RainIntensity {
    case light, medium, heavy

    var dropCount: Int {
        switch self {
        case .light:  return 12
        case .medium: return 25
        case .heavy:  return 40
        }
    }

    var speed: Double {
        switch self {
        case .light:  return 1.5
        case .medium: return 1.0
        case .heavy:  return 0.7
        }
    }
}

struct RainAnimation: View {
    let intensity: RainIntensity

    // Each raindrop has a fixed X position and random phase
    // "Phase" determines where in the fall cycle it starts
    @State private var drops: [(x: CGFloat, phase: CGFloat, speed: CGFloat)] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for drop in drops {
                    // Calculate Y position based on time + phase
                    // fmod = floating-point modulo, creates the looping effect
                    let cycleTime = time * Double(drop.speed) / intensity.speed
                    let y = CGFloat(fmod(cycleTime + Double(drop.phase), 1.0)) * (size.height + 20) - 10

                    // Draw the raindrop (a short vertical line)
                    var path = Path()
                    path.move(to: CGPoint(x: drop.x * size.width, y: y))
                    path.addLine(to: CGPoint(x: drop.x * size.width, y: y + 6))

                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.4)),
                        lineWidth: 1.2
                    )
                }
            }
        }
        .onAppear {
            drops = (0..<intensity.dropCount).map { _ in
                (
                    x: CGFloat.random(in: 0...1),
                    phase: CGFloat.random(in: 0...1),
                    speed: CGFloat.random(in: 0.8...1.3)
                )
            }
        }
    }
}

// MARK: - Snow Animation
// Falling snowflakes — similar to rain but slower, with slight horizontal drift.

struct SnowAnimation: View {

    @State private var flakes: [(x: CGFloat, phase: CGFloat, drift: CGFloat)] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for flake in flakes {
                    let cycleTime = time * 0.3  // Slow fall
                    let y = CGFloat(fmod(cycleTime + Double(flake.phase), 1.0)) * (size.height + 10)

                    // Horizontal drift — slight side-to-side sway
                    let sway = sin(time * 1.5 + Double(flake.drift) * 10) * 8

                    let x = flake.x * size.width + CGFloat(sway)

                    // Draw snowflake as a small circle
                    let rect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(0.6))
                    )
                }
            }
        }
        .onAppear {
            flakes = (0..<20).map { _ in
                (
                    x: CGFloat.random(in: 0...1),
                    phase: CGFloat.random(in: 0...1),
                    drift: CGFloat.random(in: 0...1)
                )
            }
        }
    }
}

// MARK: - Fog Animation
// Drifting semi-transparent layers that create a foggy look.

struct FogAnimation: View {
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0

    var body: some View {
        ZStack {
            // Two fog layers moving at different speeds
            RoundedRectangle(cornerRadius: 30)
                .fill(.white.opacity(0.12))
                .frame(height: 30)
                .offset(x: offset1, y: -5)

            RoundedRectangle(cornerRadius: 30)
                .fill(.white.opacity(0.08))
                .frame(height: 20)
                .offset(x: offset2, y: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                offset1 = 40
            }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                offset2 = -30
            }
        }
    }
}

// MARK: - Lightning Animation
// Quick bright flashes that simulate lightning.
// Uses a timer to randomly trigger flashes.

struct LightningAnimation: View {
    @State private var flash: Bool = false

    var body: some View {
        Rectangle()
            .fill(.white.opacity(flash ? 0.4 : 0))
            .onAppear {
                triggerFlash()
            }
    }

    private func triggerFlash() {
        // Random delay between flashes (2-6 seconds)
        let delay = Double.random(in: 2...6)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Quick flash on
            withAnimation(.easeIn(duration: 0.05)) {
                flash = true
            }
            // Quick flash off
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    flash = false
                }
                // Schedule next flash
                triggerFlash()
            }
        }
    }
}

// MARK: - Weather Header View
// The complete weather widget that goes into the dashboard.
// Combines: animation background + temperature + condition + gardening tip.

struct WeatherHeaderView: View {

    let weather: WeatherData

    var body: some View {
        ZStack(alignment: .leading) {
            // Animated weather background
            WeatherAnimationView(condition: weather.condition)
                .frame(height: 100)

            // Weather info overlay
            HStack(spacing: 14) {
                // Temperature + icon
                VStack(spacing: 4) {
                    Image(systemName: weather.condition.icon)
                        .font(.title)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)

                    Text("\(Int(weather.temperature))°")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .frame(width: 70)

                // Condition + details + tip
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(weather.condition.localizedName)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1)

                        Text("· \(weather.locationName)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    // Humidity + Wind
                    HStack(spacing: 12) {
                        Label("\(weather.humidity)%", systemImage: "humidity.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))

                        Label("\(Int(weather.windSpeed)) km/h", systemImage: "wind")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    // Gardening tip
                    Text(weather.condition.localizedTip)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Loading Weather View
// Shown while weather data is being fetched.

struct WeatherLoadingView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "cloud.sun.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)

            Text(NSLocalizedString("Loading weather...", comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview("Clear") {
    WeatherHeaderView(weather: WeatherData(
        temperature: 24,
        condition: .clear,
        humidity: 45,
        windSpeed: 12,
        locationName: "Kyiv"
    ))
    .padding()
}

#Preview("Rain") {
    WeatherHeaderView(weather: WeatherData(
        temperature: 14,
        condition: .rain,
        humidity: 85,
        windSpeed: 20,
        locationName: "Kyiv"
    ))
    .padding()
}

#Preview("Snow") {
    WeatherHeaderView(weather: WeatherData(
        temperature: -3,
        condition: .snow,
        humidity: 90,
        windSpeed: 8,
        locationName: "Kyiv"
    ))
    .padding()
}

#Preview("Thunderstorm") {
    WeatherHeaderView(weather: WeatherData(
        temperature: 18,
        condition: .thunderstorm,
        humidity: 92,
        windSpeed: 35,
        locationName: "Kyiv"
    ))
    .padding()
}
