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
            shimmeringView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shimmeringView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shimmeringView.topAnchor.constraint(equalTo: view.topAnchor),
            shimmeringView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
