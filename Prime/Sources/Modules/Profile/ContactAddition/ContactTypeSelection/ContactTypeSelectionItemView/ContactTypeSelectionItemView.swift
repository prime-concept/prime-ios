import UIKit

extension ContactTypeSelectionItemView {
    struct Appearance: Codable {
        var typeNameColor = Palette.shared.gray0
        var separatorColor = Palette.shared.gray3
    }
}

final class ContactTypeSelectionItemView: UIView {
    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var contactTypeNameLabel = UILabel()
    private let appearance: Appearance

    init(appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ContactTypeViewModel) {
        self.contactTypeNameLabel.attributedTextThemed = viewModel.name.capitalizingFirstLetter().attributed()
            .foregroundColor(self.appearance.typeNameColor)
            .primeFont(ofSize: 15, lineHeight: 18)
            .string()
    }
}

extension ContactTypeSelectionItemView: Designable {
    func addSubviews() {
        [
            self.contactTypeNameLabel,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.contactTypeNameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
