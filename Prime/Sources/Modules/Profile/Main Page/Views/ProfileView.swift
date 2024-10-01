import SnapKit
import UIKit

extension ProfileView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray4
        var shadowBackgroundColor = Palette.shared.gray5
        var shadowCornerRadius: CGFloat = 15
        var shadowOffset = CGSize(width: 0, height: 10)
        var shadowRadius: CGFloat = 30
		var shadowColor = Palette.shared.mainBlack.withAlphaComponent(0.15)
		var shadowOpacity: Float = 0.2
        var profileCardCornerRadius: CGFloat = 8
        var buttonBackgroundColor = Palette.shared.gray0
    }
}

final class ProfileView: UIView {
    private lazy var shadowView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = self.appearance.shadowBackgroundColor
        view.layer.cornerRadius = self.appearance.shadowCornerRadius
        return view
    }()

    private lazy var profileCardView: ProfileCardView = {
        let view = ProfileCardView()
        view.layer.cornerRadius = self.appearance.profileCardCornerRadius
        return view
    }()

    private lazy var addCardButton: UIButton = {
        let button = UIButton()
        button.backgroundColorThemed = self.appearance.buttonBackgroundColor
        button.setTitle("profile.card.addToWallet".localized, for: UIControl.State())
        button.layer.cornerRadius = 8
        button.titleLabel?.fontThemed = Palette.shared.primeFont.with(size: 16, weight: .medium)
        button.isHidden = true
        return button
    }()

    private lazy var profilePersonalInfoListView: ProfilePersonalInfoListView = {
        let view = ProfilePersonalInfoListView { type in
            self.onSelect(type)
        }
        return view
    }()

    private let appearance: Appearance
	let onSelect: (ProfilePersonalInfoCellViewModel.Item.Content) -> Void

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance(),
        onSelect: @escaping ((ProfilePersonalInfoCellViewModel.Item.Content) -> Void)
    ) {
        self.appearance = appearance
        self.onSelect = onSelect
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ProfileViewModel) {
        self.profileCardView.setup(with: viewModel.cardViewModel)
        self.addCardButton.setEventHandler(
            for: .touchUpInside,
            action: viewModel.cardViewModel.addCardTap
        )
        self.profilePersonalInfoListView.setup(with: viewModel.personalInfoViewModel)
		self.updateProfilePersonalInfoListViewTop()
    }

    func setAddToWalletButton(hidden: Bool) {
        self.addCardButton.isHidden = hidden
        self.updateProfilePersonalInfoListViewTop()
    }

    func setAddedToWalletView(hidden: Bool) {
        self.profileCardView.setAddedToWalletView(hidden: hidden)
    }

	override func layoutSubviews() {
		super.layoutSubviews()
		self.updateProfilePersonalInfoListViewTop()
	}

	private func updateProfilePersonalInfoListViewTop() {
        var invisibleHeaderHeight: CGFloat

        if self.addCardButton.isHidden {
            invisibleHeaderHeight = self.profileCardView.frame.maxY
        } else {
            invisibleHeaderHeight = self.addCardButton.frame.maxY - 20
        }

		invisibleHeaderHeight -= self.profilePersonalInfoListView.frame.minY
		self.profilePersonalInfoListView.invisibleHeaderHeight = invisibleHeaderHeight
	}
}

extension ProfileView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.shadowView.dropShadow(
            offset: self.appearance.shadowOffset,
            radius: self.appearance.shadowRadius,
            color: self.appearance.shadowColor,
            opacity: self.appearance.shadowOpacity
        )
    }

    func addSubviews() {
        [
            self.shadowView,
            self.profileCardView,
            self.addCardButton,
            self.profilePersonalInfoListView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self.profileCardView.snp.edges)
        }

        self.profileCardView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(15)
			make.height.equalTo(self.profileCardView.snp.width).multipliedBy(220.0 / 345)
        }

        self.addCardButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.top.equalTo(self.profileCardView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.profilePersonalInfoListView.snp.makeConstraints { make in
            make.top.equalTo(self.profileCardView.snp.top).offset(80)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}
