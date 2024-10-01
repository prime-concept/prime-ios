import UIKit

final class DetailCalendarFilesCountView: UIView {
    //MARK: - Initialisation Methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private lazy var totalLabel: UILabel = {
        let label = UILabel()
		label.text = "expandingCalendar.total".localized + ":"
        label.textAlignment = .left
        label.fontThemed = Palette.shared.body4
        label.textColorThemed = Palette.shared.gray1
        return label
    }()
    
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.fontThemed = Palette.shared.body4
        label.textColorThemed = Palette.shared.gray0
        return label
    }()
    
    //MARK: - Public Methods
    func setup(count: String) {
        self.countLabel.text = count
    }

    //MARK: - Private Methods
    private func setupView() {
        self.backgroundColorThemed = Palette.shared.gray5
        self.addSubviews()
        self.makeConstraints()
    }
}

extension DetailCalendarFilesCountView {
    func addSubviews() {
		let stack = UIStackView.horizontal(
			self.totalLabel, .hSpacer(4), self.countLabel, .hSpacer(growable: 0)
		)

		self.addSubview(stack)
		stack.make(.edges, .equalToSuperview, [10, 20, 0, -20])
    }
    
    func makeConstraints() { }
}
