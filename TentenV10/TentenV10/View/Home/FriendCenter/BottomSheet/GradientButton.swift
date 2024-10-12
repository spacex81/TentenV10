import UIKit

class GradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    private var hue: CGFloat = 0.0
    private var hueRotationTimer: Timer?
    private var gradientLayerAdded = false  // Keep track if the gradient layer has already been added
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientLayer()
    }
    
    private func setupGradientLayer() {
        // Prevent multiple insertions of the gradient layer
        if !gradientLayerAdded {
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            gradientLayer.colors = [
                UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor,
                UIColor(hue: hue + 0.1, saturation: 1, brightness: 1, alpha: 1).cgColor
            ]
            layer.insertSublayer(gradientLayer, at: 0)
            gradientLayerAdded = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the gradient layer matches the button's bounds
        gradientLayer.frame = bounds
    }
    
    func startHueRotation() {
        // Invalidate the previous timer if any, to avoid overlapping timers
        hueRotationTimer?.invalidate()
        hueRotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            self.hue += 0.01
            if self.hue > 1.0 { self.hue = 0.0 }
            self.updateGradientColors()
        }
    }
    
    func stopHueRotation() {
        hueRotationTimer?.invalidate()
        hueRotationTimer = nil
    }
    
    private func updateGradientColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true) // Disable implicit animations to avoid flickering
        gradientLayer.colors = [
            UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor,
            UIColor(hue: (hue + 0.1).truncatingRemainder(dividingBy: 1.0), saturation: 1, brightness: 1, alpha: 1).cgColor
        ]
        CATransaction.commit()
    }
}
