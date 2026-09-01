import SwiftUI
import PhotosUI
import Auth

private enum ProfileTab {
    case fotos, ranking

    var icon: String {
        switch self {
        case .fotos: return "square.grid.2x2"
        case .ranking: return "trophy"
        }
    }
}

struct ProfileView: View {
    // Grade "Fotos" mostra só o que foi publicado no Feed (post de carro +
    // post casual) — igual já funciona no perfil de outras pessoas. A
    // Wallet privada (todos os carros escaneados) continua só na aba Wallet.
    @State private var posts: [DBPost] = []
    @State private var isLoading = true
    @State private var tab: ProfileTab = .fotos
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var followersCount = 0
    @State private var followingCount = 0

    @EnvironmentObject private var authService: AuthService
    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var avatarImageData: Data?
    @State private var loadedAvatarUrl: String?
    @State private var profileEditError: String?

    private var avatarInitials: String {
        let parts = displayName.split(separator: " ")
        return parts.compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
    }

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    private var shareText: String {
        "Confere meu perfil no Spot It: @\(username)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, Theme.Spacing.md)

                    tabBar
                        .padding(.top, Theme.Spacing.md)

                    switch tab {
                    case .fotos:
                        photosGrid
                    case .ranking:
                        rankingSection
                            .padding(Theme.Spacing.md)
                    }
                }
            }
            .background(AppGradientBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("@\(username)").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { await load() }
            .refreshable { await load() }
            .onChange(of: authService.profile) { _, newProfile in
                applyProfile(newProfile)
            }
            .onAppear {
                applyProfile(authService.profile)
                Task { await loadFollowCounts() }
            }
            .overlay {
                if isLoading && posts.isEmpty {
                    WheelLoadingView(size: 44)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(
                    displayName: $displayName, username: $username, bio: $bio, avatarImageData: $avatarImageData,
                    onSave: { previous in Task { await persistProfileEdits(previous: previous) } }
                )
            }
            .alert("Não foi possível salvar", isPresented: .init(get: { profileEditError != nil }, set: { if !$0 { profileEditError = nil } })) {
                Button("OK") {}
            } message: {
                Text(profileEditError ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.lg) {
                avatarView

                statColumn(value: "\(posts.count)", label: "posts")
                statColumn(value: "\(followersCount)", label: "seguidores")
                statColumn(value: "\(followingCount)", label: "seguindo")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName).font(.subheadline).fontWeight(.semibold)
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    showEditProfile = true
                } label: {
                    Text("Editar perfil")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                ShareLink(item: shareText) {
                    Text("Compartilhar perfil")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, Theme.Spacing.xs)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarImageData, let uiImage = UIImage(data: avatarImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 74, height: 74)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(LinearGradient(colors: [.red, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 74, height: 74)
                .overlay(Text(avatarInitials).font(.title2).fontWeight(.bold).foregroundStyle(.white))
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.fotos)
            tabButton(.ranking)
        }
        .overlay(Divider(), alignment: .top)
    }

    private func tabButton(_ option: ProfileTab) -> some View {
        Button {
            tab = option
        } label: {
            Image(systemName: option.icon)
                .font(.system(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .foregroundStyle(tab == option ? .primary : .secondary)
                .overlay(alignment: .bottom) {
                    if tab == option {
                        Rectangle().fill(Color.primary).frame(height: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var photosGrid: some View {
        if posts.isEmpty {
            if !isLoading {
                EmptyStateView(icon: "photo.on.rectangle", message: "Você ainda não publicou nada. Toque no \"+\" no Feed pra postar.")
            }
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(posts) { post in
                    NavigationLink {
                        if post.isCarPost {
                            CarDetailPageView(item: WalletItem(dbPost: post))
                        } else {
                            PostDetailView(post: post)
                        }
                    } label: {
                        // Color.clear com aspectRatio como "molde" do tamanho
                        // da célula, com a foto por cima em overlay — a
                        // AsyncImage não tem tamanho próprio, então deixar
                        // ela "guiar" o aspectRatio direto (como antes) é
                        // frágil; um Color.clear sempre aceita o tamanho
                        // exato proposto pela coluna do grid.
                        Color.clear
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .overlay {
                                WalletPhotoThumb(fotoUrl: post.fotoUrl, raridade: post.raridade ?? 1)
                            }
                            .clipped()
                    }
                }
            }
        }
    }

    private var rankingSection: some View {
        // Ranking entre usuários exigiria ler wallet_items de outras
        // contas, mas a RLS só libera cada usuário ler os próprios itens —
        // não tem dado real pra mostrar até existir uma função de backend
        // dedicada (agregação sem expor linha por linha).
        EmptyStateView(icon: "trophy", message: "Ranking ainda não está disponível.")
    }

    private func load() async {
        isLoading = true
        if let userId = authService.session?.user.id {
            posts = (try? await SupabaseService.fetchPosts(userId: userId)) ?? []
        }
        await loadFollowCounts()
        isLoading = false
    }

    /// Só as contagens — chamada isolada no onAppear pra refletir follows
    /// feitos em outra tela sem recarregar a wallet inteira de novo.
    private func loadFollowCounts() async {
        guard let userId = authService.session?.user.id,
              let counts = try? await SupabaseService.followCounts(userId: userId) else { return }
        followersCount = counts.followers
        followingCount = counts.following
    }

    private func applyProfile(_ profile: Profile?) {
        guard let profile else { return }
        displayName = profile.displayName ?? profile.username
        username = profile.username
        bio = profile.bio ?? ""

        guard let avatarUrlString = profile.avatarUrl, avatarUrlString != loadedAvatarUrl,
              let url = URL(string: avatarUrlString) else { return }
        loadedAvatarUrl = avatarUrlString
        Task {
            if let (data, _) = try? await URLSession.shared.data(from: url) {
                avatarImageData = data
            }
        }
    }

    /// `previous` é o estado de antes da edição — a UI já aplicou a troca
    /// otimisticamente (username incluso, que antes nem era enviado ao
    /// backend). Se salvar falhar (username duplicado, rede, etc), volta
    /// pro valor anterior e mostra o erro de verdade em vez de engolir com
    /// `try?` e deixar o usuário achando que salvou.
    private func persistProfileEdits(previous: (displayName: String, username: String, bio: String, avatarImageData: Data?)) async {
        do {
            try await authService.updateProfile(
                username: username,
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bio.isEmpty ? nil : bio,
                avatarData: avatarImageData
            )
        } catch {
            displayName = previous.displayName
            username = previous.username
            bio = previous.bio
            avatarImageData = previous.avatarImageData
            profileEditError = (error as? AuthServiceError)?.errorDescription ?? error.localizedDescription
        }
    }
}

/// Configurações da conta — notificações, cidade e sair, mais os textos
/// legais exigidos por usar câmera/calendário (e localização, se vier a ser
/// usada no mapa). Toggle/cidade sem persistência ainda: guardam localmente
/// até existir conta de verdade pra salvar isso no backend.
private struct SettingsSheet: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var notifyLikes = true
    @State private var notifyComments = true
    @State private var notifyFollows = true
    @State private var notifyEvents = true
    @State private var city = "Naples, FL"
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Notificações") {
                    Toggle("Curtidas", isOn: $notifyLikes)
                    Toggle("Comentários", isOn: $notifyComments)
                    Toggle("Novos seguidores", isOn: $notifyFollows)
                    Toggle("Eventos", isOn: $notifyEvents)
                }

                Section("Localização") {
                    HStack {
                        Text("Cidade")
                        Spacer()
                        TextField("Cidade", text: $city)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Legal") {
                    NavigationLink("Termos de Uso") { LegalTextView(title: "Termos de Uso", text: LegalText.terms) }
                    NavigationLink("Política de Privacidade") { LegalTextView(title: "Política de Privacidade", text: LegalText.privacy) }
                }

                Section {
                    Button("Sair", role: .destructive) {
                        showLogoutConfirm = true
                    }
                }

                Section {
                    Button("Excluir Conta", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .disabled(isDeleting)

                    if let deleteError {
                        Text(deleteError).font(.footnote).foregroundStyle(.red)
                    }
                } footer: {
                    Text("Apaga permanentemente seu perfil, carros salvos, posts, curtidas, comentários, seguidores, mensagens e presenças em eventos. Não dá pra desfazer.")
                }
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .confirmationDialog("Sair da conta?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sair", role: .destructive) {
                    Task { try? await authService.signOut() }
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Excluir sua conta permanentemente?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Excluir Conta", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Essa ação não pode ser desfeita.")
            }
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        deleteError = nil
        do {
            try await authService.deleteAccount()
            dismiss()
        } catch {
            deleteError = "Não foi possível excluir a conta agora. Tente de novo."
            isDeleting = false
        }
    }
}

/// Edição de perfil com foto (PhotosPicker), nome, usuário e bio. Edita um
/// rascunho local e só aplica no perfil de verdade ao tocar Salvar —
/// Cancelar descarta as mudanças.
private struct EditProfileSheet: View {
    @Binding var displayName: String
    @Binding var username: String
    @Binding var bio: String
    @Binding var avatarImageData: Data?
    let onSave: (_ previous: (displayName: String, username: String, bio: String, avatarImageData: Data?)) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftName: String
    @State private var draftUsername: String
    @State private var draftBio: String
    @State private var draftAvatarData: Data?
    @State private var pickerItem: PhotosPickerItem?

    init(displayName: Binding<String>, username: Binding<String>, bio: Binding<String>, avatarImageData: Binding<Data?>, onSave: @escaping (_ previous: (displayName: String, username: String, bio: String, avatarImageData: Data?)) -> Void) {
        _displayName = displayName
        _username = username
        _bio = bio
        _avatarImageData = avatarImageData
        self.onSave = onSave
        _draftName = State(initialValue: displayName.wrappedValue)
        _draftUsername = State(initialValue: username.wrappedValue)
        _draftBio = State(initialValue: bio.wrappedValue)
        _draftAvatarData = State(initialValue: avatarImageData.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            avatarPreview
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section("Nome") { TextField("Nome", text: $draftName) }
                Section("Usuário") { TextField("Usuário", text: $draftUsername) }
                Section("Bio") { TextField("Bio", text: $draftBio, axis: .vertical) }
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    draftAvatarData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        Group {
            if let draftAvatarData, let uiImage = UIImage(data: draftAvatarData) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [.red, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(Image(systemName: "camera.fill").foregroundStyle(.white))
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.accentColor, Color(.systemBackground))
        }
    }

    private func save() {
        let previous = (displayName: displayName, username: username, bio: bio, avatarImageData: avatarImageData)
        displayName = draftName
        username = draftUsername
        bio = draftBio
        avatarImageData = draftAvatarData
        dismiss()
        onSave(previous)
    }
}

/// Texto legal placeholder — cobre o básico (câmera, calendário, dados do
/// carro reconhecido) mas precisa passar por um advogado antes de publicar
/// na App Store de verdade.
// ponytail: texto duplicado do site (public/privacy.html e public/terms.html
// no repo do backend) pra funcionar offline dentro do app — se um mudar, o
// outro precisa ser atualizado junto.
private enum LegalText {
    static let terms = """
    Ao usar o Spot It, você concorda em:

    • Usar o app pra fotografar e catalogar carros de forma pessoal e não comercial.
    • Não publicar conteúdo ofensivo, ilegal ou que viole direitos de terceiros no Feed, nos comentários ou nas mensagens diretas.
    • Não assediar outros usuários nem se passar por outra pessoa ou marca.

    Você pode denunciar posts/perfis e bloquear qualquer usuário diretamente no app — bloquear impede que vocês vejam conteúdo um do outro ou troquem mensagens. Revisamos denúncias em até 24h e podemos remover conteúdo ou suspender contas que violem estes termos.

    O reconhecimento de carros por IA é aproximado, só pra entretenimento — não é avaliação profissional.

    Versão completa: spotit-gamma.vercel.app/terms.html
    """

    static let privacy = """
    O Spot It coleta:

    • Conta — e-mail, usuário, nome, bio e foto de perfil.
    • Conteúdo que você cria — fotos de carros, resultado da IA, legendas, comentários, curtidas e mensagens diretas.
    • Localização — só quando você registra onde um carro foi avistado, com sua permissão.

    Usamos Supabase (banco de dados, autenticação e fotos) e Vercel (função que roda a identificação por IA) pra operar o app. Não vendemos seus dados pra terceiros.

    Você pode excluir sua conta a qualquer momento em Configurações — isso apaga permanentemente seus dados.

    Versão completa: spotit-gamma.vercel.app/privacy.html
    """
}

private struct LegalTextView: View {
    let title: LocalizedStringKey
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.subheadline)
                .padding(Theme.Spacing.md)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
}
