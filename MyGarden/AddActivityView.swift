import SwiftUI

// MARK: - Add Activity View
// A form that lets you log an activity for a plant.
// Pick what you did → optionally add a note → save.
// The date defaults to "now" but you can change it.

struct AddActivityView: View {

    // Send the new activity back to the detail screen
    var onAdd: (CareActivity) -> Void

    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var selectedType: CareType = .watered
    @State private var date: Date = Date()
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {

                // -- Activity Type Picker --
                // Shows a grid of activity types as tappable buttons
                Section {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 90))
                    ], spacing: 12) {
                        ForEach(CareType.allCases) { type in
                            activityButton(type)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("What did you do?")
                }

                // -- Date Picker --
                Section {
                    DatePicker(
                        "Date",
                        selection: $date,
                        in: ...Date(),  // can't pick future dates
                        displayedComponents: .date
                    )
                } header: {
                    Text("When?")
                }

                // -- Notes --
                Section {
                    TextField("Optional details...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("e.g. \"applied organic fertilizer\" or \"picked 2kg of cherries\"")
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let activity = CareActivity(
                            type: selectedType,
                            date: date,
                            note: note.isEmpty ? nil : note
                        )
                        onAdd(activity)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Activity Button
    // A tappable card for each activity type.
    // Selected one gets a highlighted border.

    private func activityButton(_ type: CareType) -> some View {
        let isSelected = selectedType == type

        return Button {
            selectedType = type
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : type.color)

                Text(type.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? type.color : type.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? type.color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddActivityView { activity in
        print("Added: \(activity.type.rawValue)")
    }
}
