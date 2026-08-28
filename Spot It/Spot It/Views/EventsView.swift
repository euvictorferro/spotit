import SwiftUI

struct EventsView: View {
    @State private var going: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(CarEvent.sample) { event in
                    NavigationLink(destination: EventDetailView(event: event, isGoing: binding(for: event.id))) {
                        card(event)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle("Eventos")
    }

    private func card(_ event: CarEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LinearGradient(colors: event.coverGradient, startPoint: .top, endPoint: .bottom)
                .frame(height: 90)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(.white)
                        .padding(Theme.Spacing.sm)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.name).font(.headline)
                Text(event.dateLabel).font(.footnote).foregroundStyle(.secondary)
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
                .padding(.top, 2)
            }
            .padding(Theme.Spacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { going.contains(id) },
            set: { newValue in
                if newValue { going.insert(id) } else { going.remove(id) }
            }
        )
    }

    private func toggle(_ id: UUID) {
        if going.contains(id) { going.remove(id) } else { going.insert(id) }
    }
}

#Preview {
    NavigationStack { EventsView() }
}
