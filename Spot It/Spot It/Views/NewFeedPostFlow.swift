import CoreLocation
import PhotosUI
import SwiftUI
import UIKit

/// Fluxo de publicação casual no feed (câmera + galeria, sem IA/carro) —
/// botão "+" no header do Feed. Reaproveita o CameraPicker do CaptureView
/// (mesma câmera/zoom/miniaturas), só troca "Identificar" por "Avançar" e
/// libera a galeria (o scan de carro não libera, de propósito).
struct NewFeedPostFlow: View {
    var onFinish: () -> Void

    static let maxPhotos = 10

    @State private var media: [UIImage] = []
    @State private var showGalleryPicker = false
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var showCompose = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPicker(
                onCapture: { image in
                    guard media.count < Self.maxPhotos else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { media.append(image) }
                },
                onCancel: onFinish,
                thumbnails: media,
                maxPhotos: Self.maxPhotos,
                onIdentify: media.isEmpty ? nil : { showCompose = true },
                onReset: media.isEmpty ? nil : { media.removeAll() },
                advanceButtonTitle: "Avançar",
                onPickFromGallery: media.count < Self.maxPhotos ? { showGalleryPicker = true } : nil
            )
        }
        .photosPicker(
            isPresented: $showGalleryPicker, selection: $galleryItems,
            maxSelectionCount: max(1, Self.maxPhotos - media.count), matching: .images
        )
        .onChange(of: galleryItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                for item in items where media.count < Self.maxPhotos {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        media.append(image)
                    }
                }
                galleryItems = []
            }
        }
        .fullScreenCover(isPresented: $showCompose) {
            NewFeedPostComposeView(images: media, onFinish: onFinish)
        }
        .preferredColorScheme(.dark)
    }
}

/// 2ª tela do fluxo — legenda, localização, marcar contas, e Rascunho/
/// Publicar. Sobe as fotos só ao publicar/salvar (não antes).
private struct NewFeedPostComposeView: View {
    let images: [UIImage]
    var onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var caption = ""
    @State private var location = ""
    @State private var isLoadingLocation = false
    @State private var showMentionSearch = false
    @State private var mentioned: [SearchableUser] = []
    @State private var isPublishing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    carousel
                    captionField
                    Divider()
                    locationField
                    Divider()
                    mentionsField

                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    }
                }
                .padding(Theme.Spacing.md)
                .padding(.bottom, 80)
            }
            .navigationTitle("Nova publicação")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { actionButtons }
            .sheet(isPresented: $showMentionSearch) {
                MentionSearchSheet(alreadySelected: mentioned) { user in
                    if let idx = mentioned.firstIndex(where: { $0.id == user.id }) {
                        mentioned.remove(at: idx)
                    } else {
                        mentioned.append(user)
                    }
                }
            }
        }
        .disabled(isPublishing)
    }

    private var carousel: some View {
        TabView {
            ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                Image(uiImage: image).resizable().scaledToFill().clipped()
            }
        }
        .tabViewStyle(.page)
        .aspectRatio(4 / 5, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var captionField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Legenda").font(.caption).foregroundStyle(.secondary)
            TextField("Escreva uma legenda...", text: $caption, axis: .vertical)
                .lineLimit(3...8)
        }
    }

    private var locationField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Localização").font(.caption).foregroundStyle(.secondary)
            HStack {
                TextField("Adicionar localização", text: $location)
                if isLoadingLocation {
                    ProgressView()
                } else {
                    Button { Task { await useCurrentLocation() } } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
        }
    }

    private var mentionsField: some View {
        Button {
            showMentionSearch = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Marcar pessoas")
                    if !mentioned.isEmpty {
                        Text(mentioned.map { "@\($0.username)" }.joined(separator: ", "))
                            .font(.footnote).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
    }

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                Task { await publish(isDraft: true) }
            } label: {
                Text("Rascunho").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isPublishing)

            Button {
                Task { await publish(isDraft: false) }
            } label: {
                if isPublishing {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Publicar").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPublishing)
        }
        .padding(Theme.Spacing.md)
        .background(.bar)
    }

    private func useCurrentLocation() async {
        isLoadingLocation = true
        defer { isLoadingLocation = false }
        guard let coordinate = await LocationService.shared.currentLocation() else { return }
        let point = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(point).first {
            location = [placemark.locality, placemark.administrativeArea].compactMap { $0 }.joined(separator: ", ")
        }
    }

    private func publish(isDraft: Bool) async {
        isPublishing = true
        errorMessage = nil
        do {
            let urls = try await uploadAll()
            guard !urls.isEmpty else {
                errorMessage = "Não foi possível preparar as fotos. Tente de novo."
                isPublishing = false
                return
            }
            try await SupabaseService.createCasualPost(
                photoUrls: urls,
                caption: caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : caption,
                location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location,
                mentionedUserIds: mentioned.map(\.id),
                isDraft: isDraft
            )
            onFinish()
        } catch {
            errorMessage = "Não foi possível publicar agora. Tente de novo."
        }
        isPublishing = false
    }

    /// Sequencial de propósito — até 10 fotos, sem necessidade real de
    /// concorrência aqui, e mais simples de acompanhar erro por item.
    private func uploadAll() async throws -> [String] {
        var urls: [String] = []
        for image in images {
            guard let data = image.resizedForUpload(maxDimension: 1600).jpegDataCapped(maxBytes: 900_000) else { continue }
            urls.append(try await SupabaseService.uploadPhoto(imageData: data))
        }
        return urls
    }
}

/// Busca simples pra marcar contas — mesma busca de SearchUsersView, multi-
/// seleção com toggle (marcado mostra check).
private struct MentionSearchSheet: View {
    let alreadySelected: [SearchableUser]
    let onToggle: (SearchableUser) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var results: [SearchableUser] = []

    var body: some View {
        NavigationStack {
            List(results) { user in
                Button {
                    onToggle(user)
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        AvatarView(user: user, url: user.avatarUrl, size: 36)
                        Text(user.username)
                        Spacer()
                        if alreadySelected.contains(where: { $0.id == user.id }) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .searchable(text: $search, prompt: "Buscar usuários")
            .onChange(of: search) { _, newValue in
                Task {
                    results = (try? await SupabaseService.searchProfiles(username: newValue)) ?? []
                }
            }
            .navigationTitle("Marcar pessoas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pronto") { dismiss() }
                }
            }
        }
    }
}
