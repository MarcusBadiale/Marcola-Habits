import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftData
import SwiftUI

@MCView(AddHabitProvider.self)
struct AddHabitSheet: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Button {
                        data.$showingTemplates.wrappedValue = true
                    } label: {
                        Label("Choose template", systemImage: "doc.on.doc")
                    }
                    .accessibilityIdentifier("add-habit-template-button")
                }

                Section("Info") {
                    TextField("Habit name", text: data.$name)
                        .accessibilityIdentifier("add-habit-name-field")

                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: data.icon)
                            .foregroundStyle(Color(hex: data.colorHex))
                            .font(.title2)
                    }

                    IconPicker(selectedIcon: data.$icon)
                }

                Section("Color") {
                    ColorGridPicker(selectedHex: data.$colorHex)
                }

                Section("Category") {
                    Picker("Category", selection: data.$selectedCategoryID) {
                        Text("None").tag(UUID?.none)
                        ForEach(data.categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(UUID?.some(category.id))
                        }
                    }
                    .accessibilityIdentifier("add-habit-category-picker")
                }

                Section("Frequency") {
                    Picker("Type", selection: data.$frequencyType) {
                        Text("Daily").tag(FrequencyType.daily)
                        Text("Specific days").tag(FrequencyType.specificDays)
                        Text("Times per week").tag(FrequencyType.timesPerWeek)
                    }
                    .accessibilityIdentifier("add-habit-frequency-picker")

                    if data.frequencyType == .specificDays {
                        WeekdayPicker(selectedDays: data.$selectedDays)
                    }

                    if data.frequencyType == .timesPerWeek {
                        Stepper("\(data.timesPerWeek)x per week", value: data.$timesPerWeek, in: 1...7)
                    }
                }

                Section("Goal") {
                    Stepper("Count: \(data.targetCount)", value: data.$targetCount, in: 1...100)
                        .accessibilityIdentifier("add-habit-target-stepper")

                    if data.targetCount > 1 {
                        TextField("Unit (e.g. cups, minutes)", text: data.$targetUnit)
                            .accessibilityIdentifier("add-habit-unit-field")
                    }
                }

                Section("Routine") {
                    Picker("Period", selection: data.$routine) {
                        Text("Any time").tag(Routine.anytime)
                        Text("Morning").tag(Routine.morning)
                        Text("Afternoon").tag(Routine.afternoon)
                        Text("Evening").tag(Routine.evening)
                    }
                    .accessibilityIdentifier("add-habit-routine-picker")
                }
            }
            .navigationTitle("New habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { data.cancel() }
                        .accessibilityIdentifier("add-habit-cancel-button")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { data.save() }
                        .disabled(!data.canSave)
                        .accessibilityIdentifier("add-habit-save-button")
                }
            }
            .sheet(isPresented: data.$showingTemplates) {
                TemplatePicker(templates: data.templates) { template in
                    data.applyTemplate(template)
                }
            }
        }
    }
}

private struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Weekday>

    private let weekdays: [(Weekday, String)] = [
        (.monday, "Mon"), (.tuesday, "Tue"), (.wednesday, "Wed"),
        (.thursday, "Thu"), (.friday, "Fri"), (.saturday, "Sat"), (.sunday, "Sun"),
    ]

    var body: some View {
        HStack(spacing: MCSpacing.xs) {
            ForEach(weekdays, id: \.0) { day, label in
                Text(label)
                    .font(MCTypography.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.sm)
                    .background(
                        selectedDays.contains(day) ? MCColors.accent : Color.clear,
                        in: Circle()
                    )
                    .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                    .onTapGesture {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
            }
        }
    }
}

private struct IconPicker: View {
    @Binding var selectedIcon: String

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "drop.fill", "figure.run", "brain.head.profile", "moon.fill",
        "sun.max.fill", "music.note", "graduationcap.fill", "dumbbell.fill",
        "leaf.fill", "book.fill", "paintbrush.fill", "cup.and.saucer.fill",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: MCSpacing.sm) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(
                        selectedIcon == icon ? MCColors.accent.opacity(0.2) : Color.clear,
                        in: Circle()
                    )
                    .onTapGesture { selectedIcon = icon }
            }
        }
    }
}

private struct ColorGridPicker: View {
    @Binding var selectedHex: String

    private let colors = [
        "#EF4444", "#F59E0B", "#22C55E", "#3B82F6",
        "#A855F7", "#EC4899", "#14B8A6", "#F97316",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: MCSpacing.sm) {
            ForEach(colors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(.white, lineWidth: selectedHex == hex ? 3 : 0)
                    )
                    .shadow(color: selectedHex == hex ? Color(hex: hex).opacity(0.4) : .clear, radius: 4)
                    .onTapGesture { selectedHex = hex }
            }
        }
    }
}

private struct TemplatePicker: View {
    let templates: [HabitTemplateModel]
    let onSelect: (HabitTemplateModel) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button {
                    onSelect(template)
                    dismiss()
                } label: {
                    Label(template.name, systemImage: template.icon)
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
