import UIKit

extension DetailRequestCreationUnsupportedView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 12)
        var titleColor = Palette.shared.danger

        var separatorColor = Palette.shared.gray3
    }
}

final class DetailRequestCreationUnsupportedView: UIView, TaskFieldValueInputProtocol {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.titleFont
        label.textColorThemed = self.appearance.titleColor
        return label
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private let appearance: Appearance

    private var placeholder: String? {
        didSet {
            // swiftlint:disable:next prime_font
            self.titleLabel.text = self.placeholder
        }
    }

    private var typeString: String? {
        didSet {
            // swiftlint:disable:next prime_font
            self.titleLabel.text = "Unsupported type \(String(describing: typeString))"
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 60)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: TaskCreationFieldViewModel) {
        self.placeholder = viewModel.title
        self.typeString = viewModel.form.typeString
    }
}

extension DetailRequestCreationUnsupportedView: Designable {
    func setupView() {
    }

    func addSubviews() {
        [self.titleLabel, self.separatorView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18.5)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}
