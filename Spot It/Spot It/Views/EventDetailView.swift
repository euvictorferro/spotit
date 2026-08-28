import SwiftUI
import MapKit
import EventKit

struct EventDetailView: View {
    let event: CarEvent
    @Binding var isGoing: Bool
    @State private var calendarMessage: String?

    private var position: MapCameraPosition {
        .region(MKCoordinateRegion(center: event.coordinate, span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                LinearGradient(colors: event.coverGradient, startPoint: .top, endPoint: .bottom)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(alignment: .bottomLeading) {
                        Text(event.name)
                            .font(.title2).fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(Theme.Spacing.md)
                    }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    infoRow(icon: "calendar", text: event.dateLabel)
                    infoRow(icon: "mappin.and.ellipse", text: event.location)
                    infoRow(icon: "person.2.fill", text: "\(event.attendees) confirmados · organizado por \(event.organizer)")
                }
                .card()

                Text(event.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Map(position: .constant(position)) {
                    Marker(event.name, systemImage: "car.fill", coordinate: event.coordinate)
                        .tint(Color.accentColor)
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .allowsHitTesting(false)

                HStack(spacing: Theme.Spacing.sm) {
                    Button(isGoing ? "Confirmado ✓" : "Vou") {
                        isGoing.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isGoing ? .green : Color.accentColor)

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
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(icon systemImage: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage).foregroundStyle(Color.accentColor).frame(width: 20)
            Text(text).font(.subheadline)
        }
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
                ekEvent.startDate = event.startDate
                ekEvent.endDate = event.endDate
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

#Preview {
    NavigationStack {
        EventDetailView(event: CarEvent.sample[0], isGoing: .constant(false))
    }
}
