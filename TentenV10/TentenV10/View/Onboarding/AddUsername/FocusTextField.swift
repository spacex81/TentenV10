import SwiftUI
import UIKit

struct FocusTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 32)
        textField.textColor = UIColor.white
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.delegate = context.coordinator
        textField.placeholder = "your name"
        textField.tintColor = UIColor.white
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        DispatchQueue.main.async {
            uiView.text = text
        }

        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder() // Show keyboard and focus text field
        }

        if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder() // Hide keyboard
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FocusTextField

        init(_ parent: FocusTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }
    }
}
