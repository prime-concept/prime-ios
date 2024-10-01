import UIKit

extension AviaRouteSelectionItemView {
    struct Appearance: Codable {
        var typeNameColor = Palette.shared.gray0
        var separatorColor = Palette.shared.gray3
		var tintColor = Palette.shared.brandSecondary
    }
}

final class AviaRouteSelectionItemView: UIView {
    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var selectionImageView = with(UIImageView()) {
        $0.contentMode = .scaleAspectFit
		$0.tintColorThemed = self.appearance.tintColor
    }

    private lazy var routeLabel = UILabel()
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

    func setup(with viewModel: CatalogItemRepresentable) {
        self.routeLabel.attributedTextThemed = viewModel.name.capitalizingFirstLetter().attributed()
            .foregroundColor(self.appearance.typeNameColor)
            .primeFont(ofSize: 15, lineHeight: 18)
            .string()
        let tickImage = UIImage(named: "avia_check")
        self.selectionImageView.image = viewModel.selected ? tickImage : nil
    }
}

extension AviaRouteSelectionItemView: Designable {
    func addSubviews() {
        [
            self.routeLabel,
            self.selectionImageView,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.routeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(15)
            make.trailing.equalTo(self.selectionImageView).offset(-10)
        }

        self.selectionImageView.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
