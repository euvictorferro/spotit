import SwiftUI

struct EventsView: View {
    @State private var going: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(CarEvent.sample) { event in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Image(systemName: "ticket.fill").foregroundStyle(Color.accentColor)
                            Text(event.name).font(.headline)
                        }
                        Text(event.date).font(.footnote).foregroundStyle(.secondary)
                        Text(event.location).font(.footnote).foregroundStyle(.secondary)

                        HStack {
                            Text("\(event.attendees) confirmados")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Button(going.contains(event.id) ? "Confirmado ✓" : "Vou") {
                                toggle(event.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(going.contains(event.id) ? .green : Color.accentColor)
                            .controlSize(.small)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle("Eventos")
    }

    private func toggle(_ id: UUID) {
        if going.contains(id) { going.remove(id) } else { going.insert(id) }
    }
}

#Preview {
    NavigationStack { EventsView() }
}
