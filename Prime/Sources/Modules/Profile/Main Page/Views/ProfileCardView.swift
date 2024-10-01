import UIKit
import PassKit
import WebKit

extension ProfileCardView {
	struct Appearance: Codable {
		var nameTextColor = Palette.shared.brandSecondary
		var userNameTextColor = Palette.shared.gray5
		var logoTintColor = Palette.shared.gray5
        var profileInfoTopConstrain: Int = 23
	}
}

final class ProfileCardView: UIView {
	private lazy var backgroundImageView: UIImageView = {
		let view = UIImageView()
		view.contentMode = .scaleAspectFill
		view.image = UIImage(named: "profile_card_shirt")
		return view
	}()
    
	private lazy var avatarImageView: UIImageView = {
		let imageView = UIImageView(image: UIImage(named: "profile-avatar-stub"))
		imageView.contentMode = .scaleAspectFit
		return imageView
	}()

	private lazy var logoImageView: UIImageView = {
		let imageView = UIImageView(image: UIImage(named: "logo"))
		imageView.tintColorThemed = self.appearance.logoTintColor
		imageView.contentMode = .scaleAspectFit
		imageView.isHidden = true
		return imageView
	}()

    private lazy var expiryDateImage: UIImageView = {
        let image = UIImageView(image: UIImage(named: "expiry_date"))
        image.contentMode = .scaleAspectFit
        image.isHidden = true
        return image
    }()

    private lazy var qrView: QRView = {
        let view = QRView()
        view.isHidden = true
		view.make(.width, .equal, 90)
        return view
    }()

    private lazy var addedToWalletView: AddedToWalletView = {
        let view = AddedToWalletView()
        view.isHidden = true
        return view
    }()
    
    private lazy var avatarImageViewContainer: UIView = {
        guard Config.isClubCardNumberBelowUserName else {
            return avatarImageView.inset()
        }

        let view = avatarImageView.inset([3, 3, -3, -3])
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 25.0
        view.layer.borderColorThemed = Palette.shared.brandPrimary
        return view
    }()

	private lazy var nameLabel = UILabel()
	private lazy var userNameLabel = UILabel()
    private lazy var expiryDateLabel: UILabel = {
        var label = UILabel()
        label.isHidden = true
        return label
    }()
	private let appearance: Appearance

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

	// MARK: - Public methods

	func setup(with viewModel: ProfileCardViewModel) {
		self.nameLabel.attributedTextThemed = viewModel.name.uppercased()
			.attributed()
            .foregroundColor(Config.isClubCardNumberBelowUserName
                ? appearance.userNameTextColor
                : appearance.nameTextColor
            )
			.primeFont(ofSize: 10, weight: .medium, lineHeight: 12)
			.lineBreakMode(.byWordWrapping)
			.string()

        let userNameLabelText: String = Config.isClubCardNumberBelowUserName
            ? viewModel.clubCard ?? ""
            : viewModel.userName
		self.userNameLabel.attributedTextThemed = userNameLabelText.attributed()
			.foregroundColor(self.appearance.userNameTextColor)
			.primeFont(ofSize: 18, weight: .medium, lineHeight: 21.6)
			.lineBreakMode(.byWordWrapping)
			.string()

		[self.nameLabel, self.userNameLabel].forEach {
			$0.numberOfLines = 0
			$0.lineBreakMode = .byWordWrapping
		}

        self.addedToWalletView.isHidden = !viewModel.isAddedToWallet

		if let code = viewModel.clubCard,
           let expiryDate = viewModel.expiryDate,
           !code.isEmpty,
           expiryDate.timeIntervalSinceNow.sign == .plus,
           !Config.isQRCodeHidden {
            self.qrView.qrCode = code
            self.qrView.expiryDate = expiryDate
			self.qrView.isHidden = false
        }

        if Config.isQRCodeHidden, let expireDate = viewModel.expiryDate {
            self.expiryDateLabel.attributedTextThemed = expireDate.string("MM/yy").attributed()
                .foregroundColor(self.appearance.userNameTextColor)
                .primeFont(ofSize: 18, weight: .regular, lineHeight: 21.6)
                .lineBreakMode(.byWordWrapping)
                .string()
            self.expiryDateLabel.isHidden = false
            self.expiryDateImage.isHidden = false
        }
	}

    func setAddedToWalletView(hidden: Bool) {
        self.addedToWalletView.isHidden = hidden
    }
}

extension ProfileCardView: Designable {
	func setupView() {}

	func addSubviews() {
		self.addSubview(self.backgroundImageView)

		[
			self.avatarImageViewContainer,
			self.logoImageView,
			self.nameLabel,
			self.userNameLabel,
            self.expiryDateImage,
            self.expiryDateLabel,
            self.qrView,
            self.addedToWalletView
		].forEach(self.backgroundImageView.addSubview(_:))
	}

	func makeConstraints() {
		self.backgroundImageView.make(.edges, .equalToSuperview)
		self.logoImageView.snp.makeConstraints { make in
			make.size.equalTo(CGSize(width: 19, height: 73))
			make.top.equalToSuperview().offset(self.appearance.profileInfoTopConstrain + 3)
			make.trailing.equalToSuperview().inset(23)
		}

        avatarImageView.snp.makeConstraints { $0.width.height.equalTo(44) }

        if Config.isClubCardNumberBelowUserName {
            avatarImageViewContainer.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(23)
                make.bottom.equalToSuperview().offset(-43)
            }
            
            nameLabel.snp.makeConstraints { make in
                make.leading.equalTo(self.avatarImageViewContainer.snp.trailing).offset(10)
                make.trailing.equalToSuperview().inset(106)
            }
            userNameLabel.snp.makeConstraints { make in
                make.top.equalTo(self.nameLabel.snp.bottom).offset(4)
                make.leading.equalTo(self.avatarImageViewContainer.snp.trailing).offset(10)
                make.bottom.equalToSuperview().offset(-45)
            }
        } else {
            avatarImageViewContainer.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(23)
                make.top.equalToSuperview().offset(self.appearance.profileInfoTopConstrain)
            }
            nameLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(self.appearance.profileInfoTopConstrain + 4)
                make.leading.equalTo(self.avatarImageViewContainer.snp.trailing).offset(10)
                make.trailing.equalToSuperview().inset(106)
            }
            userNameLabel.snp.makeConstraints { make in
                make.top.equalTo(self.nameLabel.snp.bottom).offset(4)
                make.leading.equalTo(self.avatarImageViewContainer.snp.trailing).offset(10)
            }
        }

        self.expiryDateImage.snp.makeConstraints { make in
            make.bottom.equalTo(self.userNameLabel.snp.bottom).inset(4)
            make.size.equalTo(CGSize(width: 16, height: 13))
            make.leading.equalTo(self.userNameLabel.snp.trailing).offset(20)
        }

        self.expiryDateLabel.snp.makeConstraints { make in
            make.top.equalTo(self.userNameLabel.snp.top)
            make.leading.equalTo(self.expiryDateImage.snp.trailing).offset(4)
        }

        self.qrView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(self.avatarImageViewContainer.snp.bottom).offset(15)
			make.leading.bottom.equalToSuperview().inset(30)
        }

        self.addedToWalletView.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.trailing.equalToSuperview().offset(Config.isClubCardNumberBelowUserName ? -20 : -25)
            make.bottom.equalToSuperview().offset(Config.isClubCardNumberBelowUserName ? -20 : -30)
        }
	}
}
