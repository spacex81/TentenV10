//import SwiftUI
//import UIKit
//
//struct FocusTextField: UIViewRepresentable {
//    @Binding var text: String
//    @Binding var isFocused: Bool
//
//    func makeUIView(context: Context) -> UITextField {
//        let textField = UITextField()
//        textField.font = UIFont.systemFont(ofSize: 32)
//        textField.textColor = UIColor.white
//        textField.autocapitalizationType = .none
//        textField.autocorrectionType = .no
//        textField.delegate = context.coordinator
//        textField.placeholder = "your name"
//        textField.tintColor = UIColor.white
//        
//        return textField
//    }
//
//    func updateUIView(_ uiView: UITextField, context: Context) {
//        DispatchQueue.main.async {
//            uiView.text = text
//        }
//
//        if isFocused && !uiView.isFirstResponder {
//            uiView.becomeFirstResponder() // Show keyboard and focus text field
//        }
//
//        if !isFocused && uiView.isFirstResponder {
//            uiView.resignFirstResponder() // Hide keyboard
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, UITextFieldDelegate {
//        var parent: FocusTextField
//
//        init(_ parent: FocusTextField) {
//            self.parent = parent
//        }
//
//        func textFieldDidChangeSelection(_ textField: UITextField) {
//            DispatchQueue.main.async {
//                self.parent.text = textField.text ?? ""
//            }
//        }
//
//        func textFieldDidBeginEditing(_ textField: UITextField) {
//            DispatchQueue.main.async {
//                self.parent.isFocused = true
//            }
//        }
//
//        func textFieldDidEndEditing(_ textField: UITextField) {
//            
//            DispatchQueue.main.async {
//                self.parent.isFocused = false
//            }
//        }
//    }
//}

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
        
        // Add target action to handle text change
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Update text only if it's different to avoid unnecessary changes
        if uiView.text != text {
            uiView.text = text
        }

        // Focus management
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder() // Show keyboard and focus text field
        } else if !isFocused && uiView.isFirstResponder {
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

        @objc func textDidChange(_ textField: UITextField) {
            // Update the text binding when the text changes
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Update focus state when editing begins
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            // Update focus state when editing ends
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }
    }
}
