import SwiftUI

struct SpeechBubbleShapeDownward: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 10
        let triangleHeight: CGFloat = 10
        let triangleWidth: CGFloat = 20
        
        // Draw the rounded rectangle
        path.addRoundedRect(in: CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - triangleHeight // Move the rectangle up to make space for the triangle
        ), cornerSize: CGSize(width: radius, height: radius))
        
        // Draw the triangle (speech bubble tail)
        let trianglePath = Path { p in
            p.move(to: CGPoint(x: rect.midX - triangleWidth / 2, y: rect.maxY - triangleHeight))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.midX + triangleWidth / 2, y: rect.maxY - triangleHeight))
            p.closeSubpath()
        }
        
        path.addPath(trianglePath)
        
        return path
    }
}

