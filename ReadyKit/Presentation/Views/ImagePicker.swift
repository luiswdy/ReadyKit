//
//  ImagePicker.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/19/25.
//

import SwiftUI
import UIKit
import AVFoundation

/// A UIKit-based image picker that supports both camera and photo library
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (Data?) -> Void

    @Environment(\.dismiss) private var dismiss

    init(sourceType: UIImagePickerController.SourceType = .camera, onImageSelected: @escaping (Data?) -> Void) {
        self.sourceType = sourceType
        self.onImageSelected = onImageSelected
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            var selectedImage: UIImage?

            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            }

            let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
            parent.onImageSelected(imageData)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
