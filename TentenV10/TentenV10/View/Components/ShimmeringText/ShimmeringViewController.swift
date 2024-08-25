import UIKit

class ShimmeringViewController: UIViewController {
    
    private let shimmeringView = ShimmeringView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
        // Configure shimmeringView
        shimmeringView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shimmeringView)
        
        NSLayoutConstraint.activate([
            shimmeringView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shimmeringView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            shimmeringView.widthAnchor.constraint(equalToConstant: 200),
            shimmeringView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func configure(with text: String, font: UIFont, fontSize: CGFloat) {
        shimmeringView.configure(text: text, font: font, fontSize: fontSize)
    }
}
