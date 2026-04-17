import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftUI

@MCView(AddHabitViewModel.self)
struct AddHabitSheet: View {
    init() {
        self._data = .init()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Button {
                        data.$showingTemplates.wrappedValue = true
                    } label: {
                        Label("Escolher template", systemImage: "doc.on.doc")
                    }
                    .accessibilityIdentifier("add-habit-template-button")
                }

                Section("Informações") {
                    TextField("Nome do hábito", text: data.$name)
                        .accessibilityIdentifier("add-habit-name-field")

                    HStack {
                        Text("Ícone")
                        Spacer()
                        Image(systemName: data.icon)
                            .foregroundStyle(Color(hex: data.colorHex))
                            .font(.title2)
                    }

                    IconPicker(selectedIcon: data.$icon)
                }

                Section("Cor") {
                    ColorGridPicker(selectedHex: data.$colorHex)
                }

                Section("Categoria") {
                    Picker("Categoria", selection: data.$selectedCategoryID) {
                        Text("Nenhuma").tag(UUID?.none)
                        ForEach(data.categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(UUID?.some(category.id))
                        }
                    }
                    .accessibilityIdentifier("add-habit-category-picker")
                }

                Section("Frequência") {
                    Picker("Tipo", selection: data.$frequencyType) {
                        Text("Diário").tag(FrequencyType.daily)
                        Text("Dias específicos").tag(FrequencyType.specificDays)
                        Text("Vezes por semana").tag(FrequencyType.timesPerWeek)
                    }
                    .accessibilityIdentifier("add-habit-frequency-picker")

                    if data.frequencyType == .specificDays {
                        WeekdayPicker(selectedDays: data.$selectedDays)
                    }

                    if data.frequencyType == .timesPerWeek {
                        Stepper("\(data.timesPerWeek)x por semana", value: data.$timesPerWeek, in: 1...7)
                    }
                }

                Section("Meta") {
                    Stepper("Quantidade: \(data.targetCount)", value: data.$targetCount, in: 1...100)
                        .accessibilityIdentifier("add-habit-target-stepper")

                    if data.targetCount > 1 {
                        TextField("Unidade (ex: copos, minutos)", text: data.$targetUnit)
                            .accessibilityIdentifier("add-habit-unit-field")
                    }
                }

                Section("Rotina") {
                    Picker("Período", selection: data.$routine) {
                        Text("Qualquer hora").tag(Routine.anytime)
                        Text("Manhã").tag(Routine.morning)
                        Text("Tarde").tag(Routine.afternoon)
                        Text("Noite").tag(Routine.evening)
                    }
                    .accessibilityIdentifier("add-habit-routine-picker")
                }
            }
            .navigationTitle("Novo hábito")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { data.cancel() }
                        .accessibilityIdentifier("add-habit-cancel-button")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { data.save() }
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
        (.monday, "Seg"), (.tuesday, "Ter"), (.wednesday, "Qua"),
        (.thursday, "Qui"), (.friday, "Sex"), (.saturday, "Sáb"), (.sunday, "Dom"),
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
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
