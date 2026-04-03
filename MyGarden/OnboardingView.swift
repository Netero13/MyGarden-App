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
    @State private var userRole: FamilyRole = .dad

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

            Text("Welcome to Arborist")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Smart care for your trees & bushes")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Swipe to continue")
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

            Text("What you can do")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "brain.head.profile.fill", color: .orange,
                          title: "Smart care intelligence",
                          subtitle: "Know when to prune, fertilize & harvest")

                featureRow(icon: "tree.fill", color: .green,
                          title: "Track your trees & bushes",
                          subtitle: "Age-based watering recommendations")

                featureRow(icon: "drop.fill", color: .blue,
                          title: "Watering reminders",
                          subtitle: "Adjusted for age and season")

                featureRow(icon: "scissors", color: .brown,
                          title: "Pruning & fertilizer guides",
                          subtitle: "Species-specific, month-by-month")

                featureRow(icon: "exclamationmark.triangle.fill", color: .red,
                          title: "Pest & disease alerts",
                          subtitle: "Know what to watch for")

                featureRow(icon: "cloud.sun.fill", color: .cyan,
                          title: "Live weather",
                          subtitle: "Seasonal tips for your climate")
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

            Text(userRole.defaultEmoji)
                .font(.system(size: 70))

            Text("Who are you?")
                .font(.title)
                .fontWeight(.bold)

            Text("Set up your profile so the family knows who did what")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Name field
            TextField("Your name", text: $userName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 40)

            // Role picker
            Picker("Role", selection: $userRole) {
                ForEach(FamilyRole.allCases) { role in
                    Text("\(role.defaultEmoji) \(role.localizedName)").tag(role)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)

            Spacer()

            // Start button
            Button {
                completeOnboarding()
            } label: {
                Text("Start Gardening!")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 24)

            // Skip button for those who don't want a profile yet
            Button("Skip for now") {
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
        // Create the first family member
        let name = userName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            let member = FamilyMember(
                name: name,
                role: userRole,
                emoji: userRole.defaultEmoji
            )
            FamilyManager.shared.add(member)
        }

        onComplete()
    }
}

#Preview {
    OnboardingView {
        print("Onboarding complete!")
    }
}
