import UIKit

final class HotelGuestsRowView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var countLabel = UILabel()

    private lazy var minusButton: UIButton = {
        var button = UIButton()
        button.setImage(UIImage(named: "avia_minus"), for: .disabled)
        button.setImage(UIImage(named: "avia_minus"), for: .normal)
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onMinusTap?()
        }
        return button
    }()

    private lazy var addButton: UIButton = {
        var button = UIButton()
        button.tintColorThemed = Palette.shared.gray0
        button.setImage(UIImage(named: "avia_plus"), for: .normal)
		button.tintColorThemed = Palette.shared.brandSecondary
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onAddTap?()
        }
        return button
    }()

    private lazy var separatorView = OnePixelHeightView()

    var field: HotelGuestsRowViewModel.Field?
    var child: HotelGuestsChildRowViewModel?

    var onMinusTap: (() -> Void)?
    var onAddTap: (() -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 55)
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DebugUtils.shared.log(sender: self, "is deinitialized")
    }

    func setup(viewModel: HotelGuestsRowViewModel) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(viewModel.title)
        self.countLabel.attributedTextThemed = Self.makeValue("\(viewModel.count)")
        self.minusButton.isEnabled = viewModel.isSubtractionEnabled
        self.field = viewModel.field

		self.updateMinusTint()
    }

    func setup(with childViewModel: HotelGuestsChildRowViewModel) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(childViewModel.title)
        self.countLabel.attributedTextThemed = Self.makeValue("\(childViewModel.age)")
        self.minusButton.isEnabled = childViewModel.isSubtractionEnabled
        self.child = childViewModel

		self.updateMinusTint()
    }

    func editCount(by amount: Int, isEnabled: Bool) {
        self.countLabel.attributedTextThemed = Self.makeValue("\(amount)")
        self.minusButton.isEnabled = isEnabled
		self.updateMinusTint()
    }

	private func updateMinusTint() {
		self.minusButton.tintColorThemed = self.minusButton.isEnabled
			? Palette.shared.brandSecondary
			: Palette.shared.gray3
	}
}

extension HotelGuestsRowView: Designable {
    func addSubviews() {
        [
            self.titleLabel,
            self.countLabel,
            self.minusButton,
            self.addButton,
            self.separatorView
        ].forEach(self.addSubview)
        self.separatorView.backgroundColorThemed = Palette.shared.gray3
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(15)
            make.trailing.equalTo(self.minusButton.snp.leading).offset(-12)
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
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }

    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0)
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
