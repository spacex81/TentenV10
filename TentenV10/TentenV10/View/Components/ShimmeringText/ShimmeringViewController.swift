import UIKit

class ShimmeringViewController: UIViewController {
    
    let shimmeringView = ShimmeringView()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Trigger setup of shimmering effect when the view is about to appear
        shimmeringView.setupShimmeringEffect()
    }
    
    func configure(with text: String, font: UIFont, fontSize: CGFloat) {
        shimmeringView.configure(text: text, font: font, fontSize: fontSize)
    }
}
