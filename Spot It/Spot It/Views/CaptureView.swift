import SwiftUI
import UIKit

struct CaptureView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var carInfo: CarInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if isLoading {
                ProgressView("Identificando o carro...")
            } else {
                Button("Tirar foto") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else { return }
            Task { await recognize(newImage) }
        }
        .sheet(item: $carInfo) { info in
            ResultView(carInfo: info, image: capturedImage)
        }
    }

    private func recognize(_ image: UIImage) async {
        guard let data = image.resizedForUpload().jpegData(compressionQuality: 0.6) else { return }
        isLoading = true
        errorMessage = nil
        do {
            carInfo = try await RecognizeService.recognize(imageData: data)
        } catch {
            errorMessage = "Não foi possível identificar o carro. Tenta de novo."
        }
        isLoading = false
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
    }
}

extension CarInfo: Identifiable {
    var id: String { modelo ?? UUID().uuidString }
}

extension UIImage {
    /// Redimensiona pra um lado máximo de 1024px — fotos da câmera em resolução
    /// total (12MP+) geram payload grande demais pro endpoint de reconhecimento.
    func resizedForUpload(maxDimension: CGFloat = 1024) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
