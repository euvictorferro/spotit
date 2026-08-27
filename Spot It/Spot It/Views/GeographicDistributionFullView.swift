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
                    Annotation(entry.info.country, coordinate: entry.info.coordinate) {
                        ZStack {
                            Circle().fill(.white).frame(width: 30, height: 30)
                            Circle().stroke(Color.accentColor, lineWidth: 2).frame(width: 30, height: 30)
                            Text("\(entry.count)").font(.caption).fontWeight(.bold).foregroundStyle(.black)
                        }
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
                    FlagBadge(flag: entry.info.flag)
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
struct FlagBadge: View {
    let flag: String

    var body: some View {
        Circle()
            .fill(Color(.tertiarySystemFill))
            .frame(width: 26, height: 26)
            .overlay(Text(flag).font(.footnote))
    }
}

#Preview {
    GeographicDistributionFullView(breakdown: [
        (CarBrandInfo.table["Ferrari"]!, 3),
        (CarBrandInfo.table["Porsche"]!, 2),
    ])
}
