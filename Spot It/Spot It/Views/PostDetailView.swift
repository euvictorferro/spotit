import SwiftUI

/// Detalhe de um post casual (sem carro) aberto a partir da grade do
/// perfil — mesmo cartão do Feed (foto/carrossel, legenda, curtidas,
/// comentários), só que centrado numa tela própria em vez de na lista.
struct PostDetailView: View {
    let post: DBPost

    var body: some View {
        ScrollView {
            FeedPostCard(post: post)
                .padding(Theme.Spacing.md)
        }
        .background(AppGradientBackground())
        .navigationBarTitleDisplayMode(.inline)
    }
}
