import UIKit

struct AviaPassengerAgeViewModel {
    enum `Type` {
        case adults, children, infants
    }

    let type: `Type`
    var value: Int
    let onUpdate: (Int) -> Void

    var title: String {
        switch self.type {
        case .adults:
            return "avia.passengers.modal.adults.title".localized
        case .children:
            return "avia.passengers.modal.children.title".localized
        case .infants:
            return "avia.passengers.modal.infants.title".localized
        }
    }

    var subtitle: String {
        switch self.type {
        case .adults:
            return "avia.passengers.modal.adults.subtitle".localized
        case .children:
            return "avia.passengers.modal.children.subtitle".localized
        case .infants:
            return "avia.passengers.modal.infants.subtitle".localized
        }
    }
}

final class AviaPassengerAgeView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var descriptionLabel = UILabel()
    private lazy var countLabel = UILabel()
    private lazy var minusButton: UIButton = {
        var button = UIButton()
        button.setImage(UIImage(named: "avia_minus"), for: .disabled)
        button.setImage(UIImage(named: "avia_minus"), for: .normal)
        button.addTarget(self, action: #selector(onMinusButtonTap), for: .touchUpInside)
        return button
    }()

    private lazy var addButton: UIButton = {
        var button = UIButton()
		button.tintColorThemed = Palette.shared.brandSecondary
        button.setImage(UIImage(named: "avia_plus"), for: .normal)
        button.addTarget(self, action: #selector(onAddButtonTap), for: .touchUpInside)
        return button
    }()

    private lazy var separatorView = OnePixelHeightView()
    
    private var model: AviaPassengerAgeViewModel?
    
    override init(frame: CGRect = .zero) {
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
		self.updateMinusTint()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(viewModel: AviaPassengerAgeViewModel) {
        self.model = viewModel
        self.titleLabel.attributedTextThemed = Self.makeTitle(viewModel.title)
        self.descriptionLabel.attributedTextThemed = Self.makeDescription(viewModel.subtitle)
        self.countLabel.attributedTextThemed = Self.makeValue("\(viewModel.value)")
        if (viewModel.type == .adults && viewModel.value == 1) || viewModel.value == 0 {
            self.minusButton.isEnabled = false
        }
		self.updateMinusTint()
    }
    
    @objc
    private func onAddButtonTap(_ button: UIButton) {
        let checkValue = self.model?.type == .adults ? 1 : 0
        self.model?.value == checkValue ? (self.minusButton.isEnabled = true) : ()
        self.model?.value += 1
        if let value = self.model?.value {
            self.countLabel.attributedTextThemed = Self.makeValue("\(String(describing: value))")
            self.model?.onUpdate(value)
        }
		self.updateMinusTint()
    }
    
    @objc
    private func onMinusButtonTap(_ button: UIButton) {
        self.model?.value -= 1
        let checkValue = self.model?.type == .adults ? 1 : 0
        self.model?.value == checkValue ? (self.minusButton.isEnabled = false) : ()
        if let value = self.model?.value {
            self.countLabel.attributedTextThemed = Self.makeValue("\(String(describing: value))")
            self.model?.onUpdate(value)
        }
		self.updateMinusTint()
    }

	private func updateMinusTint() {
		self.minusButton.tintColorThemed = self.minusButton.isEnabled
			? Palette.shared.brandSecondary
			: Palette.shared.gray3
	}
}

extension AviaPassengerAgeView: Designable {
    func addSubviews() {
        [
            self.titleLabel,
            self.descriptionLabel,
            self.countLabel,
            self.minusButton,
            self.addButton,
            self.separatorView
        ].forEach(self.addSubview)
        self.separatorView.backgroundColorThemed = Palette.shared.gray3
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.equalToSuperview().inset(15)
        }
        self.descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(15)
        }
        self.addButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        self.minusButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        self.countLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(44)
            make.leading.equalTo(self.minusButton.snp.trailing)
            make.trailing.equalTo(self.addButton.snp.leading)
        }
        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.descriptionLabel.snp.bottom).offset(10)
        }
    }
    
    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }
    
    private static func makeDescription(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, lineHeight: 14)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }
    
    private static func makeValue(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 16, lineHeight: 20)
            .foregroundColor(Palette.shared.gray0)
            .alignment(.center)
            .string()
    }
}
