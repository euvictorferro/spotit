import SwiftUI
import PhotosUI

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
    @State private var items: [WalletItem] = []
    @State private var isLoading = true
    @State private var tab: ProfileTab = .fotos
    @State private var showSettings = false
    @State private var showEditProfile = false

    @EnvironmentObject private var authService: AuthService
    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var avatarImageData: Data?
    @State private var loadedAvatarUrl: String?

    private var avatarInitials: String {
        let parts = displayName.split(separator: " ")
        return parts.compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
    }

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    private var shareText: String {
        "Confere meu perfil no Spot It: @victorferro"
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
            }
            .overlay {
                if isLoading && items.isEmpty {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(
                    displayName: $displayName, username: $username, bio: $bio, avatarImageData: $avatarImageData,
                    onSave: { Task { await persistProfileEdits() } }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.lg) {
                avatarView

                // ponytail: só o stat de posts é real — seguidores/seguindo
                // voltam quando existir sistema de seguidores no backend.
                statColumn(value: "\(items.count)", label: "posts")
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
        if items.isEmpty {
            if !isLoading {
                EmptyStateView(icon: "photo.on.rectangle", message: "Você ainda não fotografou nenhum carro.")
            }
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(items) { item in
                    AsyncImage(url: URL(string: item.fotoUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            LinearGradient(
                                colors: [Theme.rarityColor(item.raridade).opacity(0.6), Theme.rarityColor(item.raridade).opacity(0.15)],
                                startPoint: .top, endPoint: .bottom
                            )
                            .overlay(Image(systemName: "car.side.fill").foregroundStyle(Theme.rarityColor(item.raridade)))
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
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
        items = (try? await SupabaseService.fetchWalletItems()) ?? []
        isLoading = false
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

    private func persistProfileEdits() async {
        try? await authService.updateProfile(
            displayName: displayName.isEmpty ? nil : displayName,
            bio: bio.isEmpty ? nil : bio,
            avatarData: avatarImageData
        )
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
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftName: String
    @State private var draftUsername: String
    @State private var draftBio: String
    @State private var draftAvatarData: Data?
    @State private var pickerItem: PhotosPickerItem?

    init(displayName: Binding<String>, username: Binding<String>, bio: Binding<String>, avatarImageData: Binding<Data?>, onSave: @escaping () -> Void) {
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
        displayName = draftName
        username = draftUsername
        bio = draftBio
        avatarImageData = draftAvatarData
        dismiss()
        onSave()
    }
}

/// Texto legal placeholder — cobre o básico (câmera, calendário, dados do
/// carro reconhecido) mas precisa passar por um advogado antes de publicar
/// na App Store de verdade.
private enum LegalText {
    static let terms = """
    Ao usar o Spot It, você concorda em:

    • Usar o app pra fotografar e catalogar carros de forma pessoal e não comercial.
    • Não publicar conteúdo ofensivo, ilegal ou que viole direitos de terceiros no Feed ou nos comentários.
    • Respeitar outros usuários nas mensagens diretas (DM).

    O Spot It pode suspender contas que violem estes termos. Estes termos são um rascunho inicial — revisar com um advogado antes do lançamento público.
    """

    static let privacy = """
    O Spot It acessa:

    • Câmera — pra fotografar carros e identificá-los via IA.
    • Calendário — apenas quando você escolhe "Adicionar ao Calendário" em um evento.
    • Localização (futuro) — se ativarmos o mapa centrado em você, pediremos permissão específica antes.

    Fotos e dados de carros reconhecidos ficam salvos na sua conta. Não vendemos seus dados pra terceiros. Esta política é um rascunho inicial — revisar com um advogado antes do lançamento público.
    """
}

private struct LegalTextView: View {
    let title: String
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
