import UIKit

protocol AeroticketViewProtocol {
	func update(with viewModel: AeroticketViewModel)
}

final class AeroticketView: UIView, AeroticketViewProtocol {
	private let titleLabel = UILabel { (label: UILabel) in
		label.textColorThemed = Palette.shared.gray0
		label.fontThemed = Palette.shared.title2
	}

	private let sharingIcon = UIImageView { (imageView: UIImageView) in
		imageView.contentMode = .scaleAspectFit
		imageView.make(.size, .equal, [44, 44])
		imageView.tintColorThemed = Palette.shared.brandSecondary
	}

	private let cardTitleLabel = UILabel { (label: UILabel) in
		label.textColorThemed = Palette.shared.titles
		label.fontThemed = Palette.shared.smallTitle2
	}

	private let cardView = CardView()

	private lazy var cardTitleContainer = UIStackView.vertical(spacing: 10,
		self.cardTitleLabel, self.cardView
	)

	private let additionalInfoLabel = UILabel { (label: UILabel) in
		label.textColorThemed = Palette.shared.titles
		label.fontThemed = Palette.shared.smallTitle2
	}

	private lazy var additionalInfoStack = UIStackView.vertical(spacing: 10)

	private lazy var additionalInfoContainer = UIStackView.vertical(spacing: 10,
		self.additionalInfoLabel, self.additionalInfoStack
	)

	private let passengersLabel = UILabel { (label: UILabel) in
		label.textColorThemed = Palette.shared.titles
		label.fontThemed = Palette.shared.smallTitle2
	}

	private lazy var passengersStack = UIStackView.vertical(spacing: 10)

	private lazy var passengersContainer = UIStackView.vertical(spacing: 15,
		self.passengersLabel, self.passengersStack
	)

	private lazy var exchangeReturnButton = PrimeButton(appearance: .init(
		backgroundColorThemed: Palette.shared.clear,
		backgroundColorThemedHighlited: Palette.shared.brandPrimary,
		buttonBorderColor: Palette.shared.gray3
	))

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.setupUI()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func setupUI() {
		self.backgroundColorThemed = Palette.shared.gray5

		let grabberView = GrabberView()
		self.addSubview(grabberView)
		grabberView.make([.top, .centerX], .equalToSuperview, [10, 0])

		self.addSubview(self.titleLabel)
		self.titleLabel.make([.top, .leading], .equalToSuperview, [28, 15])

		self.addSubview(self.sharingIcon)
		self.sharingIcon.make([.top, .trailing], .equalToSuperview, [18, -5])

		self.addSubviews(self.exchangeReturnButton)
		self.exchangeReturnButton.make(.height, .equal, 44)
		self.exchangeReturnButton.make(.hEdges, .equalToSuperview, [15, -15])
		self.exchangeReturnButton.make(.bottom, .equal, to: self.safeAreaLayoutGuide, -10)

		self.sharingIcon.isHidden = true
		self.exchangeReturnButton.isHidden = true

		let mainStack = ScrollableStack(.vertical)
		mainStack.stackView.spacing = 25
		mainStack.showsVerticalScrollIndicator = false
		self.addSubviews(mainStack)

		mainStack.addArrangedSubviews(
			self.cardTitleContainer,
			self.additionalInfoContainer,
			self.passengersContainer
		)

		self.addSubview(mainStack)
		mainStack.make(.edges, .equalToSuperview, [77, 15, -15, -15])

		self.cardTitleLabel.addTapHandler {
			self.cardView.isHidden = !self.cardView.isHidden
		}

		self.additionalInfoLabel.addTapHandler {
			self.additionalInfoStack.isHidden = !self.additionalInfoStack.isHidden
		}

		self.passengersLabel.addTapHandler {
			self.passengersStack.isHidden = !self.passengersStack.isHidden
		}
	}

	func update(with viewModel: AeroticketViewModel) {
		self.titleLabel.textThemed = viewModel.title
		self.sharingIcon.image = UIImage(named: viewModel.sharingIconImageName)
		self.cardTitleLabel.textThemed = viewModel.bookingType
		self.cardView.update(with: viewModel.card)

		self.additionalInfoLabel.textThemed = viewModel.additionalInfoTitle
		self.additionalInfoContainer.isHidden = viewModel.additinalInfo.isEmpty
		self.additionalInfoStack.removeArrangedSubviews()
		self.additionalInfoStack.addArrangedSubviews(
			viewModel.additinalInfo.map{ self.makeAdditionalInfoRow($0.0, $0.1) }
		)
		self.passengersLabel.textThemed = viewModel.passengersTitle
		self.passengersContainer.isHidden = viewModel.passengers.isEmpty
		self.passengersStack.removeArrangedSubviews()
		self.passengersStack.addArrangedSubviews(
			viewModel.passengers.map{ self.makePassengerRow($0) }
		)

		self.sharingIcon.addTapHandler {
			viewModel.exchangeTicketAction?()
		}
	}

	private func makeAdditionalInfoRow(_ title: String, _ value: String) -> UIView {
		let titleLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray1
			label.fontThemed = Palette.shared.body3
		}

		let valueLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray0
			label.fontThemed = Palette.shared.body3
			label.numberOfLines = 0
			label.lineBreakMode = .byWordWrapping
		}

		titleLabel.textThemed = title
		valueLabel.textThemed = value

		let stack = UIStackView.horizontal(
			titleLabel, .hSpacer(growable: 15), valueLabel
		)

		stack.alignment = .top

		return stack
	}

	private func makePassengerRow(_ passenger: AeroticketViewModel.Passenger) -> UIView {
		let imageView = UIImageView { (imageView: UIImageView) in
			imageView.contentMode = .scaleAspectFit
			imageView.make(.size, .equal, [34, 34])
			imageView.tintColorThemed = Palette.shared.brandSecondary
		}

		let nameLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray0
			label.fontThemed = Palette.shared.body3
		}

		let detailsLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray1
			label.fontThemed = Palette.shared.captionReg
		}

		imageView.image = UIImage(named: passenger.iconImageName)
		nameLabel.textThemed = passenger.fullName
		detailsLabel.textThemed = passenger.details

		return UIStackView.horizontal(
			imageView, .hSpacer(15), UIStackView.vertical(
				nameLabel, .vSpacer(growable: 0), detailsLabel
			)
		)
	}
}

private class CardView: UIView {
	class AirportView: UIView {
		override init(frame: CGRect) {
			super.init(frame: frame)

			self.setupUI()
		}

		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		private func setupUI() {
			self.addSubviews(self.mainStack)
			self.mainStack.make(.edges, .equalToSuperview)
			self.mainStack.alignment = .leading
		}

		private(set) lazy var mainStack = UIStackView.vertical(
			self.cityLabel,
			self.codeLabel,
			self.terminalLabel,
			.vSpacer(10),
			self.dateLabel,
			self.timeLabel
		)

		let cityLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray5
			label.fontThemed = Palette.shared.captionReg
		}

		let codeLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray5
			label.fontThemed = Palette.shared.title
		}

		let terminalLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray5.withAlphaComponent(0.8)
			label.fontThemed = Palette.shared.captionReg
		}

		let dateLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray5
			label.fontThemed = Palette.shared.captionReg
		}

		let timeLabel = UILabel { (label: UILabel) in
			label.textColorThemed = Palette.shared.gray5
			label.fontThemed = Palette.shared.title3
		}
	}

	let departureAirportView = AirportView()
	let arrivalAirportView = AirportView()

	private lazy var flightIconContainer = UIView { view in
		view.addSubviews(
			self.flightIconImageView,
			self.flightNumberLabel
		)

		self.flightIconImageView.make([.leading, .trailing, .centerY], .equalToSuperview, [5, -5, 0])
		self.flightNumberLabel.place(under: self.flightIconImageView, +1)
		self.flightNumberLabel.make(.centerX, .equalToSuperview)
	}

	let flightIconImageView = UIImageView { (imageView: UIImageView) in
		imageView.tintColorThemed = Palette.shared.gray5
		imageView.contentMode = .scaleAspectFit
	}

	let flightNumberLabel = UILabel { (label: UILabel) in
		label.textColorThemed = Palette.shared.attention
		label.fontThemed = Palette.shared.subTitle2
		label.textAlignment = .center
	}

	let backgroundImage = UIImageView { (imageView: UIImageView) in
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = 20
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.setupUI()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		self.layer.cornerRadius = 20
		self.layer.masksToBounds = true

		self.addSubview(self.backgroundImage)
		self.backgroundImage.make(.edges, .equalToSuperview)

		let mainStack = UIStackView.horizontal(
			self.departureAirportView,
            .hSpacer(growable: 0),
			self.arrivalAirportView
		)

		self.addSubview(mainStack)
		mainStack.make(.edges(except: .top), .equalToSuperview, [15, -15, -15])

        addSubview(flightIconContainer)
        flightIconContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mainStack)
        }

		self.make(ratio: 345 ~/ 162)

		self.flightIconImageView.make(hug: 0, axis: .horizontal)
		self.departureAirportView.make(hug: 1000, axis: .horizontal)
		self.arrivalAirportView.make(hug: 1000, axis: .horizontal)
	}

	func update(with viewModel: AeroticketViewModel.Card) {
		with(viewModel.departure) { model in
			self.departureAirportView.cityLabel.textThemed = model.city
			self.departureAirportView.codeLabel.textThemed = model.code
			self.departureAirportView.terminalLabel.textThemed = model.terminal
			self.departureAirportView.dateLabel.textThemed = model.date
			self.departureAirportView.timeLabel.textThemed = model.time
		}

		with(viewModel.arrival) { model in
			self.arrivalAirportView.mainStack.alignment = .trailing
			self.arrivalAirportView.cityLabel.textThemed = model.city
			self.arrivalAirportView.codeLabel.textThemed = model.code
			self.arrivalAirportView.terminalLabel.textThemed = model.terminal
			self.arrivalAirportView.dateLabel.textThemed = model.date
			self.arrivalAirportView.timeLabel.textThemed = model.time
		}

		self.flightNumberLabel.textThemed = viewModel.flightNumber

		self.backgroundImage.image = UIImage(named: viewModel.backgroundImageName)
		self.flightIconImageView.image = UIImage(named: viewModel.flightIconImageName)
	}
}
