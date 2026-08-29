import SwiftUI
import UIKit
import AVFoundation
import PhotosUI
import Combine

/// Fluxo de captura: câmera fica aberta o tempo todo. Cada foto tirada
/// encolhe pra um slot numa grade de até 5 (frente/trás/lateral/interior/
/// detalhe ajudam bastante em carros raros), sem sair da câmera — só quando
/// o usuário aperta "Identificar" é que manda pra IA.
struct CaptureView: View {
    static let maxPhotos = 5

    @Environment(\.dismiss) private var dismiss
    @State private var capturedImages: [UIImage] = []
    @State private var isIdentifying = false
    @State private var carInfo: CarInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    #if DEBUG
    @State private var debugPickerItem: PhotosPickerItem?
    #endif

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isIdentifying, let lastImage = capturedImages.last {
                identifyingView(lastImage)
            } else {
                cameraView

                #if DEBUG
                debugGalleryButton
                #endif
            }
        }
        .sheet(item: $carInfo, onDismiss: retake) { info in
            ResultView(carInfo: info, image: capturedImages.first, onFinish: { dismiss() })
        }
        .preferredColorScheme(.dark)
    }

    private var cameraView: some View {
        let onIdentify: (() -> Void)? = capturedImages.isEmpty ? nil : { Task { await startIdentifying() } }
        let onReset: (() -> Void)? = capturedImages.isEmpty ? nil : { retake() }
        return CameraPicker(
            onCapture: appendCapturedImage,
            onCancel: { dismiss() },
            thumbnails: capturedImages,
            maxPhotos: Self.maxPhotos,
            onIdentify: onIdentify,
            onReset: onReset
        )
        .ignoresSafeArea()
    }

    private func appendCapturedImage(_ image: UIImage) {
        guard capturedImages.count < Self.maxPhotos else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            capturedImages.append(image)
        }
    }

    #if DEBUG
    /// Só em build de debug — Simulador não tem câmera, isso permite testar
    /// o fluxo com uma foto qualquer da galeria. Some no build de release:
    /// usuário final não tem upload, só captura ao vivo.
    private var debugGalleryButton: some View {
        VStack {
            Spacer()
            HStack {
                PhotosPicker(selection: $debugPickerItem, matching: .images) {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.35), in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, 210)
        }
        .onChange(of: debugPickerItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                appendCapturedImage(image)
            }
        }
    }
    #endif

    /// Tela cheia mostrada só depois de apertar "Identificar" — a última
    /// foto de fundo com a animação de scan, ou o erro com opção de voltar
    /// pra câmera (mantendo as fotos já tiradas) ou recomeçar do zero.
    private func identifyingView(_ image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            if isLoading {
                ScanningOverlay()
            }

            VStack {
                Spacer()
                VStack(spacing: Theme.Spacing.sm) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        HStack {
                            if capturedImages.count < Self.maxPhotos {
                                Button("+ Adicionar ângulo") { isIdentifying = false }
                                    .buttonStyle(.borderedProminent)
                            }
                            Button("Recomeçar") { retake() }
                                .buttonStyle(.bordered)
                        }
                    } else {
                        Text("Identificando o carro...")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.55))
            }
        }
    }

    private func retake() {
        capturedImages = []
        carInfo = nil
        errorMessage = nil
        isIdentifying = false
    }

    private func startIdentifying() async {
        isIdentifying = true
        let datas = capturedImages.compactMap { $0.resizedForUpload().jpegData(compressionQuality: 0.6) }
        guard !datas.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            carInfo = try await RecognizeService.recognize(imagesData: datas)
        } catch {
            errorMessage = "Não foi possível identificar o carro. Tenta de novo."
        }
        isLoading = false
    }
}

/// Animação de "escaneando" sobre a foto capturada — mistura grade de radar
/// (malha + varredura + pontos de leitura acendendo) com um contorno de
/// moldura sendo traçado, como se a IA estivesse lendo a imagem de verdade.
private struct ScanningOverlay: View {
    @State private var sweepDown = false
    @State private var traceProgress: CGFloat = 0
    @State private var dotsOn = false

    private let dotPositions: [UnitPoint] = [
        .init(x: 0.3, y: 0.38), .init(x: 0.62, y: 0.55),
        .init(x: 0.45, y: 0.7), .init(x: 0.78, y: 0.45),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                GridLines()
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.accentColor.opacity(0.7), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
                    .offset(y: sweepDown ? geo.size.height : -120)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false), value: sweepDown)

                ForEach(0..<dotPositions.count, id: \.self) { i in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.accentColor, radius: 4)
                        .opacity(dotsOn ? 1 : 0)
                        .scaleEffect(dotsOn ? 1 : 0.4)
                        .position(x: geo.size.width * dotPositions[i].x, y: geo.size.height * dotPositions[i].y)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(Double(i) * 0.4),
                            value: dotsOn
                        )
                }

                ScanFrame()
                    .trim(from: 0, to: traceProgress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .shadow(color: Color.accentColor, radius: 6)
                    .padding(28)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            sweepDown = true
            dotsOn = true
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                traceProgress = 1
            }
        }
    }
}

/// Malha fina de fundo — parte do efeito "grade de radar".
private struct GridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 32
        var x: CGFloat = 0
        while x <= rect.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: rect.height)); x += step }
        var y: CGFloat = 0
        while y <= rect.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: rect.width, y: y)); y += step }
        return path
    }
}

/// Moldura arredondada que é "traçada" (trim animado) por cima da foto —
/// sugere a IA reconhecendo os limites do carro.
private struct ScanFrame: Shape {
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: 24)
    }
}

extension CarInfo: Identifiable {
    var id: String { modelo ?? UUID().uuidString }
}

extension UIImage {
    /// Redimensiona pra um lado máximo de 1568px (ponto ideal de visão da
    /// Anthropic — acima disso a imagem só é reamostrada de novo do lado
    /// deles) — fotos da câmera em resolução total (12MP+) geram payload
    /// grande demais, mas cortar mais que isso perde detalhe (crachás,
    /// texto) que ajuda a reconhecer variantes específicas.
    func resizedForUpload(maxDimension: CGFloat = 1568) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

// MARK: - Câmera customizada (AVFoundation)

/// Sessão de câmera própria (em vez de UIImagePickerController) — o picker
/// do sistema deixa uma faixa preta embaixo quando os controles nativos são
/// escondidos, porque o preview mantém o tamanho/posição original. Com
/// AVCaptureVideoPreviewLayer + resizeAspectFill controlamos o preview pra
/// preencher a tela inteira de verdade.
final class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var isConfigured = false
    private var isFlashOn = false
    var onCapture: ((UIImage) -> Void)?

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else { return }
            self?.setUp()
        }
    }

    private func setUp() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        start()
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in session.startRunning() }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in session.stopRunning() }
    }

    func setFlash(_ on: Bool) { isFlashOn = on }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if output.supportedFlashModes.contains(isFlashOn ? .on : .off) {
            settings.flashMode = isFlashOn ? .on : .off
        }
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.onCapture?(image) }
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewLayerView {
        let view = PreviewLayerView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewLayerView, context: Context) {}

    final class PreviewLayerView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

/// Preview de câmera em tela cheia + moldura com cantos, flash, X pra sair,
/// grade de miniaturas das fotos já tiradas e o obturador — sem ícone de
/// galeria de propósito, o app não aceita upload do usuário final, só
/// captura ao vivo.
struct CameraPicker: View {
    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void
    var thumbnails: [UIImage]
    var maxPhotos: Int
    var onIdentify: (() -> Void)?
    var onReset: (() -> Void)?

    @StateObject private var camera = CameraModel()
    @State private var isFlashOn = false

    var body: some View {
        ZStack {
            // A view de preview é só vídeo ao vivo — sem isso, ela às vezes
            // "rouba" o toque antes de chegar nos botões do overlay por cima.
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            CameraOverlayView(
                onCapture: { camera.capturePhoto() },
                onToggleFlash: { on in
                    isFlashOn = on
                    camera.setFlash(on)
                },
                onDismiss: onCancel,
                thumbnails: thumbnails,
                maxPhotos: maxPhotos,
                onIdentify: onIdentify,
                onReset: onReset
            )
            .zIndex(1)
        }
        .onAppear {
            camera.onCapture = onCapture
            camera.configureIfNeeded()
            camera.start()
        }
        .onDisappear { camera.stop() }
    }
}

/// Moldura com cantos, botão de flash, X pra sair, grade de miniaturas e o
/// obturador — visual de referência (câmera dedicada de identificação, sem
/// controles extras).
private struct CameraOverlayView: View {
    let onCapture: () -> Void
    let onToggleFlash: (Bool) -> Void
    let onDismiss: () -> Void
    let thumbnails: [UIImage]
    let maxPhotos: Int
    let onIdentify: (() -> Void)?
    let onReset: (() -> Void)?
    @State private var isFlashOn = false

    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack {
                    iconButton("xmark", action: onDismiss)
                    Spacer()
                    iconButton(isFlashOn ? "bolt.fill" : "bolt.slash.fill") {
                        isFlashOn.toggle()
                        onToggleFlash(isFlashOn)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                // A view ignora a safe area (câmera em tela cheia), então
                // sem isso os botões ficavam colados na status bar/notch.
                .padding(.top, geo.safeAreaInsets.top + Theme.Spacing.md)

                Spacer()

                ViewfinderFrame()
                    .padding(.horizontal, 36)
                    .frame(height: 260)

                Spacer()

                thumbnailGrid
                    .padding(.bottom, Theme.Spacing.md)

                HStack {
                    Group {
                        if let onReset {
                            Button("Recomeçar", action: onReset)
                                .buttonStyle(.plain)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 90, alignment: .leading)

                    Spacer()

                    Button(action: onCapture) {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 74, height: 74)
                            .overlay(Circle().fill(.white).frame(width: 62, height: 62))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())

                    Spacer()

                    Group {
                        if let onIdentify {
                            Button("Identificar", action: onIdentify)
                                .buttonStyle(.borderedProminent)
                                .tint(.accentColor)
                        }
                    }
                    .frame(width: 90, alignment: .trailing)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, 40)
            }
        }
    }

    /// Grade de até 5 slots — preenchidos mostram a miniatura, vazios ficam
    /// como um contorno tracejado indicando quantas fotos ainda cabem.
    private var thumbnailGrid: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<maxPhotos, id: \.self) { index in
                if index < thumbnails.count {
                    Image(uiImage: thumbnails[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.6), lineWidth: 1))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: 44, height: 44)
                }
            }
        }
    }

    private func iconButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}

/// Cantos em L marcando a área de foco — puramente visual, a foto captura
/// a tela inteira independente da moldura.
private struct ViewfinderFrame: View {
    var body: some View {
        GeometryReader { geo in
            let length: CGFloat = 28
            let corners: [(CGPoint, [CGFloat])] = [
                (.init(x: 0, y: 0), [1, 1]),
                (.init(x: geo.size.width, y: 0), [-1, 1]),
                (.init(x: 0, y: geo.size.height), [1, -1]),
                (.init(x: geo.size.width, y: geo.size.height), [-1, -1]),
            ]
            ForEach(0..<corners.count, id: \.self) { i in
                let (point, direction) = corners[i]
                Path { path in
                    path.move(to: CGPoint(x: point.x, y: point.y + length * direction[1]))
                    path.addLine(to: point)
                    path.addLine(to: CGPoint(x: point.x + length * direction[0], y: point.y))
                }
                .stroke(.white, lineWidth: 3)
            }
        }
    }
}
