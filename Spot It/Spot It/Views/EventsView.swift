import SwiftUI

struct EventsView: View {
    @State private var events: [DBEvent] = []
    @State private var showCreate = false
    @State private var loadFailed = false
    @State private var toggleErrorMessage: String?

    var body: some View {
        Group {
            if events.isEmpty && loadFailed {
                EmptyStateView(icon: "wifi.slash", message: "Não deu pra carregar os eventos agora. Puxe pra atualizar.")
            } else if events.isEmpty {
                EmptyStateView(icon: "ticket", message: "Nenhum evento por perto ainda.")
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach($events) { $event in
                            NavigationLink(destination: EventDetailView(event: $event)) {
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
        .alert("Ops", isPresented: .init(get: { toggleErrorMessage != nil }, set: { if !$0 { toggleErrorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(toggleErrorMessage ?? "")
        }
        .task { await load() }
        .preferredColorScheme(.dark)
    }

    private func load() async {
        loadFailed = false
        do {
            events = try await SupabaseService.fetchEvents()
        } catch {
            loadFailed = true
        }
    }

    private func dateLabel(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private func card(_ event: DBEvent) -> some View {
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
        do {
            let nowGoing = try await SupabaseService.toggleGoing(eventId: event.id)
            guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
            events[index].isGoing = nowGoing
            events[index].attendeeCount += nowGoing ? 1 : -1
        } catch {
            toggleErrorMessage = "Não deu pra confirmar presença agora. Tente de novo."
        }
    }
}

private struct CreateEventSheet: View {
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
    @State private var eventDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var description = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Nome") { TextField("Ex: Cars & Coffee Naples", text: $name) }
                Section("Local") { TextField("Ex: Naples, FL", text: $location) }
                Section("Data") { DatePicker("", selection: $eventDate, in: Date()...).labelsHidden() }
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
                    if isCreating {
                        ProgressView()
                    } else {
                        Button("Criar") { Task { await create() } }
                            .disabled(name.isEmpty || location.isEmpty)
                    }
                }
            }
        }
    }

    private func create() async {
        guard eventDate > Date() else {
            errorMessage = "A data do evento precisa ser no futuro."
            return
        }
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
