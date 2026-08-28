import SwiftUI

/// Bandeira desenhada em SwiftUI (vetor, não emoji) — círculo nítido, sem
/// o recorte "grudento" do glifo de emoji. Cobre os países que já aparecem
/// em CarBrandInfo; país desconhecido cai num globo cinza neutro.
struct VectorFlagView: View {
    let country: String
    var size: CGFloat = 26

    var body: some View {
        Circle()
            .fill(Color.black.opacity(0.001)) // garante hit-area/clip mesmo sem fundo
            .frame(width: size, height: size)
            .overlay(flagContent.clipShape(Circle()))
            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
    }

    @ViewBuilder
    private var flagContent: some View {
        switch country {
        case "EUA":
            usa
        case "Itália":
            stripes([.green, .white, .red], vertical: true)
        case "França":
            stripes([.blue, .white, .red], vertical: true)
        case "Alemanha":
            stripes([.black, .red, .yellow], vertical: false)
        case "Reino Unido":
            unionJack
        case "Suécia":
            nordicCross(background: .blue, cross: .yellow)
        case "Japão":
            japan
        case "Coreia do Sul":
            ZStack { Color.white; Circle().fill(.red).frame(width: size * 0.4) }
        default:
            ZStack {
                Color(.tertiarySystemFill)
                Image(systemName: "flag.fill").font(.system(size: size * 0.45)).foregroundStyle(.secondary)
            }
        }
    }

    private func stripes(_ colors: [Color], vertical: Bool) -> some View {
        Group {
            if vertical {
                HStack(spacing: 0) { ForEach(0..<colors.count, id: \.self) { colors[$0] } }
            } else {
                VStack(spacing: 0) { ForEach(0..<colors.count, id: \.self) { colors[$0] } }
            }
        }
    }

    private var usa: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in (i.isMultiple(of: 2) ? Color.red : Color.white) }
            }
            Rectangle().fill(.blue).frame(width: size * 0.5, height: size * 0.42)
        }
    }

    private var unionJack: some View {
        ZStack {
            Color.blue
            Path { p in
                p.move(to: .init(x: 0, y: 0)); p.addLine(to: .init(x: size, y: size))
                p.move(to: .init(x: size, y: 0)); p.addLine(to: .init(x: 0, y: size))
            }.stroke(.white, lineWidth: size * 0.14)
            Rectangle().fill(.white).frame(width: size, height: size * 0.22)
            Rectangle().fill(.white).frame(width: size * 0.22, height: size)
            Rectangle().fill(.red).frame(width: size, height: size * 0.12)
            Rectangle().fill(.red).frame(width: size * 0.12, height: size)
        }
    }

    private func nordicCross(background: Color, cross: Color) -> some View {
        ZStack {
            background
            Rectangle().fill(cross).frame(width: size, height: size * 0.2).offset(y: -size * 0.06)
            Rectangle().fill(cross).frame(width: size * 0.2, height: size).offset(x: -size * 0.1)
        }
    }

    private var japan: some View {
        ZStack {
            Color.white
            Circle().fill(.red).frame(width: size * 0.5)
        }
    }
}

#Preview {
    HStack {
        ForEach(["EUA", "Itália", "França", "Alemanha", "Reino Unido", "Suécia", "Japão", "Brasil"], id: \.self) {
            VectorFlagView(country: $0)
        }
    }
    .padding()
    .background(Color.black)
}
