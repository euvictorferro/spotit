import SwiftUI
import UIKit

struct CaptureView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var carInfo: CarInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Identificando o carro...")
            } else {
                Button("Tirar foto") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
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
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
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
