import SwiftUI
import MapKit

struct GeographicDistributionFullView: View {
    let breakdown: [(info: CarBrandInfo, count: Int)]
    @Environment(\.dismiss) private var dismiss

    private var totalCount: Int { breakdown.reduce(0) { $0 + $1.count } }

    var body: some View {
        ZStack(alignment: .top) {
            Map {
                ForEach(breakdown, id: \.info.country) { entry in
                    Annotation(entry.info.country, coordinate: entry.info.coordinate, anchor: .bottom) {
                        MapPinAnnotation(country: entry.info.country, count: entry.count)
                    }
                }
            }
            .ignoresSafeArea()

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(Theme.Spacing.md)

            VStack {
                Spacer()
                panel
            }
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("\(totalCount) carro\(totalCount == 1 ? "" : "s") distribuído\(totalCount == 1 ? "" : "s") em \(breakdown.count) país\(breakdown.count == 1 ? "" : "es")")
                .font(.subheadline).fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.md)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))

            ForEach(breakdown, id: \.info.country) { entry in
                HStack {
                    FlagBadge(country: entry.info.country)
                    Text(entry.info.country).font(.subheadline)
                    Spacer()
                    Text("\(entry.count) carro\(entry.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
    }
}

/// Ícone de bolinha com a bandeira dentro, em vez do emoji solto.
/// Bandeira em emblema redondo — o emoji de bandeira é retangular por
/// natureza, então renderizamos maior que o círculo e cortamos com
/// clipShape pra preencher de borda a borda, tipo moeda/selo.
struct FlagBadge: View {
    let country: String
    var size: CGFloat = 26

    var body: some View {
        VectorFlagView(country: country, size: size)
    }
}

#Preview {
    GeographicDistributionFullView(breakdown: [
        (CarBrandInfo.table["Ferrari"]!, 3),
        (CarBrandInfo.table["Porsche"]!, 2),
    ])
}
