import UIKit

extension DetailRequestCreationSeparatorView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 15)
        var titleColor = Palette.shared.mainBlack

        var separatorColor = Palette.shared.gray3
    }
}

final class DetailRequestCreationSeparatorView: UIView, TaskFieldValueInputProtocol {
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

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 65)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: TaskCreationFieldViewModel) {
        // swiftlint:disable:next prime_font
        self.titleLabel.text = viewModel.title
    }
}

extension DetailRequestCreationSeparatorView: Designable {
    func addSubviews() {
        [self.titleLabel, self.separatorView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.separatorView.snp.top).offset(-20.5)
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
