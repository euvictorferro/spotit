import SwiftUI

/// Slider de faixa (piso/teto) reutilizável — usado no filtro de Ano e de
/// Preço da Wallet. `histogram` é opcional: se vier, desenha um gráfico de
/// distribuição em cima (quantos carros caem em cada faixa), com a trilha
/// do slider embaixo. Barras dentro da faixa selecionada ficam destacadas.
struct RangeSliderView: View {
    let bounds: ClosedRange<Double>
    @Binding var low: Double
    @Binding var high: Double
    var histogram: [Int] = []
    var formatValue: (Double) -> String = { String(format: "%.0f", $0) }

    private let thumbSize: CGFloat = 22
    private let barsHeight: CGFloat = 44

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !histogram.isEmpty {
                GeometryReader { geo in
                    histogramBars(width: geo.size.width)
                }
                .frame(height: barsHeight)
            }

            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill)).frame(height: 4)

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: x(for: high, width: width) - x(for: low, width: width), height: 4)
                        .offset(x: x(for: low, width: width))

                    thumb(value: $low, width: width, otherValue: high, isLow: true)
                    thumb(value: $high, width: width, otherValue: low, isLow: false)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 28)

            HStack {
                Text(formatValue(low)).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(formatValue(high)).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func histogramBars(width: CGFloat) -> some View {
        let maxCount = max(histogram.max() ?? 1, 1)
        let bucketWidth = (bounds.upperBound - bounds.lowerBound) / Double(histogram.count)
        let barWidth = width / CGFloat(histogram.count)

        return HStack(alignment: .bottom, spacing: 1) {
            ForEach(Array(histogram.enumerated()), id: \.offset) { index, count in
                let bucketStart = bounds.lowerBound + Double(index) * bucketWidth
                let bucketEnd = bucketStart + bucketWidth
                let isInSelection = bucketEnd > low && bucketStart < high

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isInSelection ? Color.accentColor : Color(.tertiarySystemFill))
                    .frame(width: max(0, barWidth - 1), height: max(4, barsHeight * CGFloat(count) / CGFloat(maxCount)))
            }
        }
        .frame(width: width, height: barsHeight, alignment: .bottom)
    }

    private func x(for value: Double, width: CGFloat) -> CGFloat {
        guard bounds.upperBound > bounds.lowerBound else { return 0 }
        let ratio = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return CGFloat(ratio) * width
    }

    private func value(forX x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return bounds.lowerBound }
        let ratio = max(0, min(1, x / width))
        return bounds.lowerBound + Double(ratio) * (bounds.upperBound - bounds.lowerBound)
    }

    private func thumb(value: Binding<Double>, width: CGFloat, otherValue: Double, isLow: Bool) -> some View {
        Circle()
            .fill(.white)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(radius: 2)
            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            .offset(x: x(for: value.wrappedValue, width: width) - thumbSize / 2)
            .gesture(
                DragGesture()
                    .onChanged { drag in
                        let newValue = self.value(forX: drag.location.x, width: width)
                        if isLow {
                            value.wrappedValue = min(newValue, otherValue)
                        } else {
                            value.wrappedValue = max(newValue, otherValue)
                        }
                    }
            )
    }
}

#Preview {
    struct Demo: View {
        @State private var low = 390_000.0
        @State private var high = 2_000_000.0
        var body: some View {
            RangeSliderView(bounds: 45_000...3_000_000, low: $low, high: $high, histogram: [1, 3, 5, 2, 4, 1, 2, 0, 1, 1]) { "$\(Int($0))" }
                .padding()
        }
    }
    return Demo()
}
