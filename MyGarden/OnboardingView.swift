import SwiftUI

// MARK: - Onboarding View
// A welcoming screen shown on first launch.
// Introduces the app and lets the user set up their name before starting.
//
// This screen only appears ONCE — after completing it, we save a flag
// to UserDefaults so it never shows again.
//
// Key concept: @AppStorage
// We use @AppStorage("hasCompletedOnboarding") to track whether the
// user has seen this screen. AppStorage reads/writes UserDefaults.

struct OnboardingView: View {

    // When done, this closure tells the parent to switch to the main app
    var onComplete: () -> Void

    // Current page in the walkthrough
    @State private var currentPage: Int = 0

    // User input
    @State private var userName: String = ""

    var body: some View {
        TabView(selection: $currentPage) {

            // Page 1: Welcome
            welcomePage
                .tag(0)

            // Page 2: Features overview
            featuresPage
                .tag(1)

            // Page 3: Set up your profile
            profilePage
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon
            Image(systemName: "tree.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text(NSLocalizedString("Welcome to Arborist", comment: ""))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(NSLocalizedString("Smart care for your trees & bushes", comment: ""))
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Text(NSLocalizedString("Swipe to continue", comment: ""))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 40)
        }
        .padding()
    }

    // MARK: - Page 2: Features

    private var featuresPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(NSLocalizedString("What you can do", comment: ""))
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "brain.head.profile.fill", color: .orange,
                          title: NSLocalizedString("Smart care intelligence", comment: ""),
                          subtitle: NSLocalizedString("Know when to prune, fertilize & harvest", comment: ""))

                featureRow(icon: "tree.fill", color: .green,
                          title: NSLocalizedString("Track your trees & bushes", comment: ""),
                          subtitle: NSLocalizedString("Age-based watering recommendations", comment: ""))

                featureRow(icon: "drop.fill", color: .blue,
                          title: NSLocalizedString("Watering reminders", comment: ""),
                          subtitle: NSLocalizedString("Adjusted for age and season", comment: ""))

                featureRow(icon: "scissors", color: .brown,
                          title: NSLocalizedString("Pruning & fertilizer guides", comment: ""),
                          subtitle: NSLocalizedString("Species-specific, month-by-month", comment: ""))

                featureRow(icon: "exclamationmark.triangle.fill", color: .red,
                          title: NSLocalizedString("Pest & disease alerts", comment: ""),
                          subtitle: NSLocalizedString("Know what to watch for", comment: ""))

                featureRow(icon: "cloud.sun.fill", color: .cyan,
                          title: NSLocalizedString("Live weather", comment: ""),
                          subtitle: NSLocalizedString("Seasonal tips for your climate", comment: ""))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Page 3: Profile Setup

    private var profilePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)

            Text(NSLocalizedString("What's your name?", comment: ""))
                .font(.title)
                .fontWeight(.bold)

            Text(NSLocalizedString("Your name will appear in the activity log", comment: ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Name field
            TextField(NSLocalizedString("Your name", comment: ""), text: $userName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 40)

            Spacer()

            // Start button
            Button {
                completeOnboarding()
            } label: {
                Text(NSLocalizedString("Start Gardening!", comment: ""))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 24)

            // Skip button for those who don't want a name yet
            Button(NSLocalizedString("Skip for now", comment: "")) {
                onComplete()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Complete Onboarding

    private func completeOnboarding() {
        // Save the user's name to UserDefaults
        let name = userName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            UserDefaults.standard.set(name, forKey: "userName")
        }

        onComplete()
    }
}

#Preview {
    OnboardingView {
        print("Onboarding complete!")
    }
}
