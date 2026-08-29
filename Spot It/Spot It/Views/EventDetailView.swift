import SwiftUI
import MapKit
import EventKit

struct EventDetailView: View {
    @State var event: DBEvent
    @State private var calendarMessage: String?

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = event.lat, let lng = event.lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private var position: MapCameraPosition? {
        guard let coordinate else { return nil }
        return .region(MKCoordinateRegion(center: coordinate, span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                LinearGradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.2), Color(red: 0.02, green: 0.04, blue: 0.07)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(alignment: .bottomLeading) {
                        Text(event.name)
                            .font(.title2).fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(Theme.Spacing.md)
                    }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    infoRow(icon: "calendar", text: event.eventDate.formatted(date: .abbreviated, time: .shortened))
                    infoRow(icon: "mappin.and.ellipse", text: event.location)
                    infoRow(icon: "person.2.fill", text: "\(event.attendeeCount) confirmados · organizado por \(event.organizerUsername)")
                }
                .glassCard()

                if let description = event.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let coordinate, let position {
                    Map(position: .constant(position)) {
                        Marker(event.name, systemImage: "car.fill", coordinate: coordinate)
                            .tint(Color.accentColor)
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .allowsHitTesting(false)
                }

                HStack(spacing: Theme.Spacing.sm) {
                    Button(event.isGoing ? "Confirmado ✓" : "Vou") {
                        Task { await toggleGoing() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(event.isGoing ? .green : Color.accentColor)

                    Button {
                        addToCalendar()
                    } label: {
                        Label("Adicionar ao Calendário", systemImage: "calendar.badge.plus")
                    }
                    .buttonStyle(.bordered)
                }

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(AppGradientBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private func infoRow(icon systemImage: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage).foregroundStyle(Color.accentColor).frame(width: 20)
            Text(text).font(.subheadline)
        }
    }

    private func toggleGoing() async {
        guard let nowGoing = try? await SupabaseService.toggleGoing(eventId: event.id) else { return }
        event.isGoing = nowGoing
        event.attendeeCount += nowGoing ? 1 : -1
    }

    /// Integração real com o Calendário do iOS (EventKit) — não é mock, cria
    /// o evento de verdade no calendário padrão do usuário.
    private func addToCalendar() {
        let store = EKEventStore()
        store.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                guard granted, error == nil else {
                    calendarMessage = "Não foi possível acessar o calendário. Verifique as permissões em Ajustes."
                    return
                }
                let ekEvent = EKEvent(eventStore: store)
                ekEvent.title = event.name
                ekEvent.location = event.location
                ekEvent.notes = event.description
                ekEvent.startDate = event.eventDate
                ekEvent.endDate = event.eventDate.addingTimeInterval(3 * 3600)
                ekEvent.calendar = store.defaultCalendarForNewEvents
                do {
                    try store.save(ekEvent, span: .thisEvent)
                    calendarMessage = "Adicionado ao seu calendário! 🎉"
                } catch {
                    calendarMessage = "Erro ao salvar no calendário."
                }
            }
        }
    }
}
