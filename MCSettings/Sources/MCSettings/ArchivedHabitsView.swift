import MCDesignSystem
import MCDomain
import MCShared
import SwiftUI

struct ArchivedHabitsView: View {

    @Provider var provider = ArchivedHabitsProvider()

    var body: some View {
        Group {
            if provider.isEmpty {
                empty
            } else {
                list
            }
        }
        .navigationTitle("Archived habits")
        .confirmationDialog(
            "Delete this habit?",
            isPresented: Binding(
                get: { provider.isConfirmingDelete },
                set: { if !$0 { provider.cancelDelete() } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { provider.confirmDelete() }
                .accessibilityIdentifier("settings-archived-delete-confirm")
            Button("Cancel", role: .cancel) { provider.cancelDelete() }
                .accessibilityIdentifier("settings-archived-delete-cancel")
        } message: {
            Text("This also deletes all its check-ins. This can't be undone.")
        }
    }

    private var empty: some View {
        ContentUnavailableView(
            "No archived habits",
            systemImage: "archivebox",
            description: Text("Habits you archive show up here. You can bring them back any time.")
        )
        .accessibilityIdentifier("settings-archived-empty")
    }

    private var list: some View {
        List {
            ForEach(Array(provider.archivedHabits.enumerated()), id: \.element.id) { index, habit in
                ArchivedHabitRow(
                    name: habit.name,
                    icon: habit.icon,
                    colorHex: habit.colorHex,
                    logCount: habit.logs.count
                )
                // `.combine` antes do identifier: sem isso a row vira dois StaticText soltos
                // (nome e contagem) e o identifier resolve pra mais de um elemento.
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("settings-archived-row-\(index)")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Sem full swipe: deletar cascateia os check-ins, então tem que passar
                    // pela confirmação.
                    Button(role: .destructive) {
                        provider.requestDelete(habit)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityIdentifier("settings-archived-delete-\(index)")

                    Button {
                        provider.unarchive(habit)
                    } label: {
                        Label("Unarchive", systemImage: "arrow.uturn.backward")
                    }
                    .tint(MCColors.success)
                    .accessibilityIdentifier("settings-archived-unarchive-\(index)")
                }
            }
        }
        .listStyle(.plain)
        .accessibilityIdentifier("settings-archived-list")
    }
}

private struct ArchivedHabitRow: View {

    let name: String
    let icon: String
    let colorHex: String
    let logCount: Int

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: colorHex))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(name)
                    .font(MCTypography.body)

                Text("\(logCount) check-ins")
                    .font(MCTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, MCSpacing.xs)
    }
}

#Preview {
    NavigationStack {
        ArchivedHabitsView()
    }
    .modelContainer(PreviewContainer.make())
}
