import SwiftUI

/// Loading padrão do app — a roda em wireframe girando em loop, como se o
/// carro estivesse andando. Substitui o ProgressView() do sistema nas telas
/// principais.
struct WheelLoadingView: View {
    var size: CGFloat = 44
    @State private var isSpinning = false

    var body: some View {
        Image("LoadingWheel")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
    }
}

#Preview {
    WheelLoadingView(size: 80)
        .background(Color.black)
}
