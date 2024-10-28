import SwiftUI
import UIKit

struct StrokeTextView: View {
    let text: String
    let textColor: Color
//    let font: PretendardFont
    let fontSize: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat
    
    private var storkeUIColor: UIColor { UIColor(strokeColor) }
    
    init(
        text: String,
        textColor: Color,
//        font: PretendardFont,
        fontSize: CGFloat,
        strokeColor: Color,
        strokeWidth: CGFloat = 15
    ) {
        self.text = text
        self.textColor = textColor
//        self.font = font
        self.fontSize = fontSize
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        StrokeText(
            text: text,
//            font: UIFont(name: font.rawValue, size: fontSize)!,
            strokeColor: storkeUIColor,
            strokeWidth: strokeWidth
        )
        .overlay {
            Text(text)
//                .font(.custom(font.rawValue, size: fontSize))
                .foregroundStyle(textColor)
        }
    }
}
