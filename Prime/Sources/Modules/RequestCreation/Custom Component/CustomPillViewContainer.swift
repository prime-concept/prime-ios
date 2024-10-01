import UIKit

final class CustomPillViewContainer: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.setup()
    }
    
    //MARK: - Public Methods
    func setup(image: UIImage?, title: String, action: @escaping (() -> Void)) {
        let stackView = UIStackView()
        stackView.axis = .horizontal

        // Create a UIImageView for the plus image
        let plusImageView = UIImageView(image: image)
        plusImageView.tintColor = .black 
        
        // Create a UILabel for the text
        let textLabel = UILabel()
        textLabel.text = title + "\t"
        textLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Add the plus image and text label to the stack view
        stackView.addArrangedSubview(plusImageView)
        stackView.addArrangedSubview(textLabel)
        
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        
        stackView.backgroundColor = .white
        stackView.clipsToBounds = true
        stackView.layer.cornerRadius = 22
        
        stackView.addTapHandler {
			action()
        }
        
        self.addSubview(stackView)
        stackView.make(.height, .equal, 44)
        stackView.make(.edges, .equalToSuperview)
    }
    
    //MARK: - Private Methods
    private func setup() {
        self.backgroundColor = .clear
    }
}
