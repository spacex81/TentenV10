import SwiftUI

struct SpeechBubbleShapeUpward: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 10
        let triangleHeight: CGFloat = 10
        let triangleWidth: CGFloat = 20
        let cornerRadius: CGFloat = 4
        
        // Draw the rounded rectangle
        path.addRoundedRect(in: CGRect(
            x: rect.minX,
            y: rect.minY + triangleHeight, // Move the rectangle down to make space for the triangle
            width: rect.width,
            height: rect.height - triangleHeight
        ), cornerSize: CGSize(width: radius, height: radius))
        
        // Draw the triangle (speech bubble tail)
        let trianglePath = Path { p in
            p.move(to: CGPoint(x: rect.midX - triangleWidth / 2, y: rect.minY + triangleHeight))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX + triangleWidth / 2, y: rect.minY + triangleHeight))
            p.closeSubpath()
        }
        
        path.addPath(trianglePath)
        
        return path
    }
}
