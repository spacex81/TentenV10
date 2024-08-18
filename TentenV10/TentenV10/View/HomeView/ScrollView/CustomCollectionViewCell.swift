import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CustomCollectionViewCell"
   
    var friend: FriendRecord?
    
    var onTap: (() -> Void)? // Closure to handle tap event

    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.layer.cornerRadius = frame.size.width / 2
        contentView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCell))
        contentView.addGestureRecognizer(tapGestureRecognizer)
        
        longPressGestureRecognizer.minimumPressDuration = 0.1
        contentView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc private func didTapCell() {
        onTap?() // Trigger the tap callback
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with friend: FriendRecord) {
        if let imageData = friend.profileImageData {
            imageView.image = UIImage(data: imageData)
        } else {
            imageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }
}


