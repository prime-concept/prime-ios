import UIKit
import MapKit

extension RequestItemMainView {
    struct Appearance: Codable {
		var titleFont = Palette.shared.smallTitle2
		var subtitleFont = Palette.shared.captionReg
		var dateFont = Palette.shared.captionReg

        var titleTextColor = Palette.shared.gray0

        var subtitleAddressTextColor = Palette.shared.accentAddress
		var subtitleRegularTextColor = Palette.shared.gray0

        var selectedTextColor = Palette.shared.gray5
        var dateTextColor = Palette.shared.gray1
        var backgroundColor = Palette.shared.gray5
        var selectedBackgroundColor = Palette.shared.brandPrimary
        var logoBorderWidth: CGFloat = 0.5
        var logoBorderColor = Palette.shared.brandSecondary

		var reservationTextColor = Palette.shared.gray5
		var reservationBackgroundColor = Palette.shared.brandPrimary

		var tintColor = Palette.shared.brandSecondary
    }
}

final class RequestItemMainView: UIView {
	private let appearance: Appearance

	private var spacersRatioConstraint: NSLayoutConstraint?

    private lazy var logoView = TaskInfoTypeView()
	private lazy var logoViewLeadingSpacer = UIView()

	private var titleTopSpaceConstraint: NSLayoutConstraint?

	private lazy var statusHeader = self.statusLabel.inset([4, 10, -2, -10]) { header in
		header.backgroundColorThemed = self.appearance.reservationBackgroundColor
	}

	private lazy var statusLabel = UILabel()

	private func themed(label: String) -> NSAttributedString {
		label.localized.attributed()
			.foregroundColor(self.appearance.reservationTextColor)
			.primeFont(ofSize: 12, weight: .medium, lineHeight: 14)
			.alignment(.left)
			.string()
	}

    private lazy var titleLabel = UILabel()
	private lazy var subtitleLabel = UILabel()
	private lazy var subtitleLabelContainer = self.subtitleLabel.inset([4, 0, -4, 0])
	private lazy var titleDateSeparator: UIView = .vSpacer(4)
    private lazy var dateLabel = UILabel()

    private lazy var payItemView = HomePayItemView()
    private lazy var payItemContainer = UIView()
	private lazy var chevron = UIStackView(.horizontal) { hStack in
		hStack.addArrangedSubviews(
			UIStackView(.vertical){ vStack in
				vStack.addArrangedSubviews(
					.vSpacer(growable: 0),
					UIImageView { (imageView: UIImageView) in
						imageView.image = UIImage(named: "request_arrow_right")
						imageView.tintColorThemed = self.appearance.tintColor
						imageView.contentMode = .scaleAspectFit
						imageView.make(.size, .equal, [7, 14])
					},
					.vSpacer(growable: 0)
				)
				vStack[0].make(.height, .equal, to: vStack[2])
			},
			.hSpacer(23)
		)
		hStack.isHidden = true
	}

	private lazy var subtitleTextColor = self.appearance.subtitleRegularTextColor

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
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

	private static let cache = NSAttributedStringsCache()

    func setup(with viewModel: ActiveTaskViewModel) {
        self.setup(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            date: viewModel.formattedDate,
            image: viewModel.image,
			isCompleted: viewModel.isCompleted,
			hasReservation: viewModel.hasReservation,
			task: viewModel.task,
			isInputAccessory: viewModel.isInputAccessory
        )

		if viewModel.routesToTaskDetails {
			self.chevron.isHidden = false

			TaskPersistenceService.shared.task(with: viewModel.taskID).done { task in
				self.setupTaskDetails(for: task)
			}
		}

		self.logoViewLeadingSpacer.snp.updateConstraints { make in
			make.width.equalTo(viewModel.imageLeading)
		}

		self.logoView.snp.updateConstraints { make in
			make.size.equalTo(viewModel.imageSize)
		}
    }

    func setup(with viewModel: CompletedTaskViewModel) {
        self.setup(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            date: viewModel.date,
            image: viewModel.image,
			isCompleted: false,
			hasReservation: false,
			task: viewModel.task
        )

        self.payItemContainer.isHidden = true
        if viewModel.type == .waitingForPayment {
            guard let order = viewModel.order else {
                return
            }
            self.payItemContainer.isHidden = false
            self.payItemView.setup(with: order) {
                viewModel.order?.onTap()
            }
        }
    }

    func setSelected(_ isSelected: Bool) {
        self.backgroundColorThemed = isSelected ? self.appearance.selectedBackgroundColor : self.appearance.backgroundColor
        self.logoView.setSelected(isSelected)
        let selectedTextColor = self.appearance.selectedTextColor
        self.titleLabel.textColorThemed = isSelected ? selectedTextColor : self.appearance.titleTextColor
        self.subtitleLabel.textColorThemed = isSelected ? selectedTextColor : self.subtitleTextColor
        self.dateLabel.textColorThemed = isSelected ? selectedTextColor : self.appearance.dateTextColor
    }

    // MARK: - Helpers
	private lazy var taskIdLabel = UILabel { (label: UILabel) in
		label.font = .systemFont(ofSize: 24)
		label.textColor = .red
		label.adjustsFontSizeToFitWidth = true
		label.numberOfLines = 1
		label.backgroundColor = .white.withAlphaComponent(0.6)

		self.addSubview(label)
		label.make(.center, .equalToSuperview)
		label.make(.hEdges, .equalToSuperview, [10, -10])
	}

	private let etagFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYYMMddHHmmssSSS"
		return formatter
	}()

    private func setup(
        title: String?,
        subtitle: String?,
        date: String?,
        image: UIImage?,
		isCompleted: Bool,
		hasReservation: Bool,
		task: Task? = nil,
		isInputAccessory: Bool = false
    ) {
		let title = title ?? ""
		let subtitle = subtitle ?? ""
		let date = date ?? ""

		if let task = task {
			let taskId = task.taskID
			let streTag = String((task.etag?.description ?? "").prefix(17))
			let eTagFormatted = self.etagFormatter.date(from: streTag)?.string("YYYY/MM/dd HH:mm:ss.SSS") ?? streTag

			self.taskIdLabel.text = "\(taskId) (\(task.events.count))[\(task.attachedFiles.count)] etag: \(eTagFormatted) type: \(task.taskType?.id ?? -1)"
			self.taskIdLabel.isHidden = !UserDefaults[bool: "showsTaskIdsOnTasks"]
		} else {
			self.taskIdLabel.isHidden = true
		}

		if self.titleLabel.text != title  {
			self.titleLabel.attributedTextThemed = Self.cache.string(for: "titleLabel", raw: title) {
				title.attributed()
					.foregroundColor(appearance.titleTextColor)
					.themedFont(self.appearance.titleFont)
					.lineBreakMode(.byTruncatingTail)
					.string()
			}
		}

		self.subtitleTextColor = (task?.hasAddress ?? false) ? self.appearance.subtitleAddressTextColor : self.appearance.subtitleRegularTextColor

		if self.subtitleLabel.text != subtitle {
			self.subtitleLabel.attributedTextThemed = Self.cache.string(for: "subtitleLabel", raw: subtitle) {
				subtitle.attributed()
					.foregroundColor(self.subtitleTextColor)
					.themedFont(self.appearance.subtitleFont)
					.lineBreakMode(.byTruncatingTail)
					.string()
			}
		}

		self.subtitleLabelContainer.removeTapHandler()

        if task?.googleMapsURL != nil, UserDefaults[bool: "addressTapEnabled"],
           let source = UIViewController.topmostPresented {
            self.subtitleLabelContainer.addTapHandler { [weak source] in
                guard source != nil else { return }
                if let lat = task?.latitude, let long = task?.longitude {
                    self.onMapTap(location: CLLocationCoordinate2D(latitude: lat, longitude: long))
                }
            }
        }

		if self.dateLabel.text != date {
			self.dateLabel.attributedTextThemed = Self.cache.string(for: "dateLabel", raw: date) {
				date.attributed()
					.foregroundColor(appearance.dateTextColor)
					.themedFont(self.appearance.dateFont)
					.lineBreakMode(.byTruncatingTail)
					.string()
			}
		}

        self.logoView.set(image: image)

        self.subtitleLabelContainer.isHidden = subtitle.isEmpty
		self.titleDateSeparator.isHidden = !subtitle.isEmpty || date.isEmpty

		var statusTitle = ""
		if hasReservation {
			statusTitle = "task.hasReservation".localized
		}

		if isCompleted {
            statusTitle = "task.isCompleted.temp".localized
		}
		
		self.statusHeader.isHidden = statusTitle.isEmpty
		if self.statusLabel.text != statusTitle {
			self.statusLabel.attributedTextThemed = self.themed(label: statusTitle)
		}

		self.titleTopSpaceConstraint?.constant = hasReservation ? 5 : 8

		if isInputAccessory && (subtitle.isEmpty || date.isEmpty) {
			self.titleTopSpaceConstraint?.constant += 4
		}
    }

	private func setupTaskDetails(for task: Task?) {
		guard let task = task else {
			return
		}

		self.addTapHandler { [weak self] in
			guard let self else { return }

			let sourceViewController = self.viewController?.topmostPresentedOrSelf
			let taskDetailsViewController = TaskDetailsViewController()
			taskDetailsViewController.update(with: task)
			sourceViewController?.presentModal(controller: taskDetailsViewController)
		}
	}
    
    private func onMapTap(location: CLLocationCoordinate2D?) {
        let mapVC = PartialMapViewController()
        mapVC.location = location
        parentViewController?.present(mapVC, animated: true)
    }
}

extension RequestItemMainView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor

        self.logoView.layer.borderWidth = self.appearance.logoBorderWidth
        self.logoView.layer.borderColorThemed = self.appearance.logoBorderColor
    }

	func addSubviews() {
		let contentHStack = UIStackView()
        contentHStack.axis = .horizontal

		let vStack = UIStackView()
        vStack.axis = .vertical

		let logoStack = with(UIStackView()) { stack in
			stack.axis = .vertical
			let spacer1 = UIView.vSpacer(growable: 0)
			let spacer2 = UIView.vSpacer(growable: 0)
			stack.addArrangedSubviews(
				spacer1,
				self.logoView,
				spacer2
			)
			spacer2.make(.height, .equal, to: spacer1)
		}

		let titleTopSpacer = UIView()
		self.titleTopSpaceConstraint = titleTopSpacer.make(.height, .equal, 5)

		vStack.addArrangedSubviews(
			self.titleLabel,
			self.subtitleLabelContainer,
			self.titleDateSeparator,
			self.dateLabel
		)

        self.payItemContainer.addSubview(self.payItemView)
        self.payItemContainer.isHidden = true
        self.payItemView.make(
            [.leading, .trailing, .centerY],
            .equalToSuperview,
            [5, 0, 0]
        )

		contentHStack.addArrangedSubviews (
			self.logoViewLeadingSpacer,
			logoStack,
			.hSpacer(12),
			vStack.inset([5, 0, -5, 0]),
            self.payItemContainer,
			.hSpacer(10),
			self.chevron
		)

		contentHStack.alignment = .center

		let mainVStack = UIStackView.vertical(
			self.statusHeader,
			contentHStack
		)

		self.addSubview(mainVStack)
		mainVStack.make(.edges, .equalToSuperview)
	}

	func makeConstraints() {
		self.logoView.snp.makeConstraints { make in
			make.size.equalTo(CGSize(width: 36, height: 36))
		}
		self.logoViewLeadingSpacer.snp.makeConstraints { make in
			make.width.equalTo(9)
		}
        self.payItemView.make(.size, .equal, [85, 32])
        [self.titleLabel, self.dateLabel, self.subtitleLabel].forEach {
            $0.setContentHuggingPriority(.required, for: .vertical)
        }

		self.make(.height, .greaterThanOrEqual, 50)
    }
}

