import UIKit

class AddButtonCell: UICollectionViewCell {
    static let reuseIdentifier = "AddButtonCell"
    
    var onTap: (() -> Void)?
    var isPressing: Bool = false {
        didSet {
            animateScale(isPressing: isPressing)
        }
    }

    private let addButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 2.0
        button.layer.cornerRadius = 35 // Adjust if needed
        button.backgroundColor = .clear
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            addButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Attach target to button for touch events
        addButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    @objc private func didTapButton() {
        onTap?() // Trigger the tap callback
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AddButtonCell {
    private func animateScale(isPressing: Bool) {
        let scaleTransform = isPressing ? CGAffineTransform(scaleX: 0.001, y: 0.001) : .identity
        
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.6, // Adjust damping for bounce effect
            initialSpringVelocity: 0.8,  // Adjust velocity for bounce intensity
            options: [],
            animations: {
                self.transform = scaleTransform
            },
            completion: nil
        )
    }
}
