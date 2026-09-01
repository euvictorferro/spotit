import SwiftUI

/// Primeira tela do fluxo de auth — apresentação + escolha entre
/// Entrar/Criar conta, antes do formulário (referência: apps tipo carteira
/// digital, hero + destaques + 2 CTAs).
struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Spacer()
                Spacer()

                VStack(spacing: Theme.Spacing.sm) {
                    Text("Spotted")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Registre e colecione os carros que você avista")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: Theme.Spacing.sm) {
                    highlight(icon: "camera.viewfinder", title: "Reconhecimento por IA", subtitle: "Tire uma foto e identificamos o carro")
                    highlight(icon: "map", title: "Coleção geolocalizada", subtitle: "Veja onde você já flagrou cada modelo")
                }

                Spacer()
                Spacer()

                VStack(spacing: Theme.Spacing.sm) {
                    NavigationLink {
                        AuthView(isSignUp: false)
                    } label: {
                        Text("Entrar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink {
                        AuthView(isSignUp: true)
                    } label: {
                        Text("Criar conta")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(AppGradientBackground())
            .background(alignment: .top) {
                // Mesmo enfeite decorativo do header da Wallet — roda em
                // wireframe quase transparente, sangrando pelo topo da tela.
                Image("LoadingWheel")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 340, height: 340)
                    .opacity(0.16)
                    .offset(y: -120)
                    .allowsHitTesting(false)
            }
            .clipped()
        }
    }

    private func highlight(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

#Preview {
    WelcomeView().environmentObject(AuthService())
}
