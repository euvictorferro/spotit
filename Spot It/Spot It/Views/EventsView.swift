import SwiftUI

struct EventsView: View {
    @State private var events: [DBEvent] = []
    @State private var showCreate = false

    var body: some View {
        Group {
            if events.isEmpty {
                EmptyStateView(icon: "ticket", message: "Nenhum evento por perto ainda.")
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(events) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                card(event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
                .refreshable { await load() }
            }
        }
        .background(AppGradientBackground())
        .navigationTitle("Eventos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateEventSheet(onCreated: { Task { await load() } })
        }
        .task { await load() }
        .preferredColorScheme(.dark)
    }

    private func load() async {
        events = (try? await SupabaseService.fetchEvents()) ?? []
    }

    private func coverGradient(for event: DBEvent) -> [Color] {
        let palette: [[Color]] = [
            [.red, .orange], [.purple, .indigo], [.blue, .cyan],
            [.pink, .purple], [.green, .mint], [.teal, .blue],
        ]
        let index = abs(event.id.uuidString.hashValue) % palette.count
        return palette[index]
    }

    private func dateLabel(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private func card(_ event: DBEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LinearGradient(colors: coverGradient(for: event), startPoint: .top, endPoint: .bottom)
                .frame(height: 90)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(.white)
                        .padding(Theme.Spacing.sm)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.name).font(.walletHeadline)
                Text(dateLabel(for: event.eventDate)).font(.footnote).foregroundStyle(.secondary)
                Text(event.location).font(.footnote).foregroundStyle(.secondary)

                HStack {
                    Text("\(event.attendeeCount) confirmados")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button(event.isGoing ? "Confirmado ✓" : "Vou") {
                        Task { await toggle(event) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(event.isGoing ? .green : Color.accentColor)
                    .controlSize(.small)
                }
                .padding(.top, 2)
            }
            .padding(Theme.Spacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func toggle(_ event: DBEvent) async {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        guard let nowGoing = try? await SupabaseService.toggleGoing(eventId: event.id) else { return }
        events[index].isGoing = nowGoing
        events[index].attendeeCount += nowGoing ? 1 : -1
    }
}

private struct CreateEventSheet: View {
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
    @State private var eventDate = Date()
    @State private var description = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Nome") { TextField("Ex: Cars & Coffee Naples", text: $name) }
                Section("Local") { TextField("Ex: Naples, FL", text: $location) }
                Section("Data") { DatePicker("", selection: $eventDate).labelsHidden() }
                Section("Descrição (opcional)") { TextField("Conta mais sobre o evento...", text: $description, axis: .vertical) }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Novo Evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") { Task { await create() } }
                        .disabled(name.isEmpty || location.isEmpty || isCreating)
                }
            }
        }
    }

    private func create() async {
        isCreating = true
        defer { isCreating = false }
        do {
            try await SupabaseService.createEvent(
                name: name, location: location, eventDate: eventDate,
                description: description.isEmpty ? nil : description
            )
            dismiss()
            onCreated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { EventsView() }
}
