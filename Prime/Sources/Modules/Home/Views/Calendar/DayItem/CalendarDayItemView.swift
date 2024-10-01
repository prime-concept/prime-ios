import SnapKit
import UIKit

extension CalendarDayItemView {
    enum State {
        case selected, withEvents, withoutEvents
    }
}

extension CalendarDayItemView {
    struct Appearance: Codable {
        var topTextColor = Palette.shared.gray0
        var mainTextColor = Palette.shared.gray0
        var bottomTextColor = Palette.shared.gray0

        var hasEventsIndicatorBackgroundColor = Palette.shared.brandPrimary
        var hasEventsIndicatorCornerRadius: CGFloat = 2

        var containerCornerRadius: CGFloat = 4
        var containerBackgroundColor = Palette.shared.gray5

        var todayColor = Palette.shared.brandSecondary

		var topFont = Palette.shared.primeFont.with(size: 12)
		var mainFont = Palette.shared.primeFont.with(size: 16)
		var bottomFont = Palette.shared.primeFont.with(size: 12)
    }
}

final class CalendarDayItemView: UIView {
    private lazy var containerView = UIView()

    private lazy var topLabel = UILabel()

    private lazy var mainLabel = UILabel()

    private lazy var bottomLabel = UILabel()

    private lazy var hasEventsIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = self.appearance.hasEventsIndicatorBackgroundColor
        view.layer.cornerRadius = self.appearance.hasEventsIndicatorCornerRadius
        return view
    }()

    private var state: State = .withoutEvents {
        didSet {
            switch self.state {
            case .selected:
                self.setSelectedState()
            case .withEvents:
                self.setWithEventsState()
            case .withoutEvents:
                self.setWithoutEventsState()
            }
        }
    }

    private let appearance: Appearance

    private var hasEventsIndicatorViewBottomConstraint: Constraint?
    private var bottomLabelBottomConstraint: Constraint?

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

    private func setSelectedState() {
        self.hasEventsIndicatorView.isHidden = true
        self.bottomLabel.isHidden = false

        self.containerView.dropShadow(
            offset: .init(width: 0, height: 4),
            radius: 10,
            color: Palette.shared.mainBlack,
            opacity: 0.15
        )
        self.containerView.backgroundColorThemed = self.appearance.containerBackgroundColor
        self.containerView.layer.cornerRadius = self.appearance.containerCornerRadius

        self.bottomLabelBottomConstraint?.activate()
        self.hasEventsIndicatorViewBottomConstraint?.deactivate()
    }

    private func setWithEventsState() {
        self.hasEventsIndicatorView.isHidden = false
        self.bottomLabel.isHidden = true
        self.containerView.resetShadow()
        self.containerView.layer.cornerRadius = 0
        self.containerView.backgroundColorThemed = Palette.shared.clear

        self.bottomLabelBottomConstraint?.activate()
        self.hasEventsIndicatorViewBottomConstraint?.deactivate()
    }

    private func setWithoutEventsState() {
        self.hasEventsIndicatorView.isHidden = true
        self.bottomLabel.isHidden = true
        self.containerView.resetShadow()
        self.containerView.layer.cornerRadius = 0
        self.containerView.backgroundColorThemed = Palette.shared.clear

        self.bottomLabelBottomConstraint?.activate()
        self.hasEventsIndicatorViewBottomConstraint?.deactivate()
    }

    func set(state: State) {
        self.state = state
    }

	private static let cache = NSAttributedStringsCache()

    func setup(with viewModel: CalendarDayItemViewModel) {

		self.topLabel.attributedTextThemed = Self.cache.string(for: "topLabel", raw: viewModel.dayOfWeek) {
			viewModel.dayOfWeek.attributed()
				.font(self.appearance.topFont)
				.lineHeight(14)
				.string()
		}

		self.mainLabel.attributedTextThemed = Self.cache.string(for: "mainLabel", raw: viewModel.dayNumber) {
			viewModel.dayNumber.attributed()
				.font(self.appearance.mainFont)
				.lineHeight(20)
				.string()
		}

		self.bottomLabel.attributedTextThemed = Self.cache.string(for: "bottomLabel", raw: viewModel.month) {
			viewModel.month.attributed()
				.font(self.appearance.bottomFont)
				.lineHeight(14)
				.string()
		}

        self.topLabel.textColorThemed = viewModel.isToday ? self.appearance.todayColor : self.appearance.topTextColor
        self.mainLabel.textColorThemed = viewModel.isToday ? self.appearance.todayColor : self.appearance.mainTextColor
        self.bottomLabel.textColorThemed = viewModel.isToday ? self.appearance.todayColor : self.appearance.bottomTextColor
    }
}

extension CalendarDayItemView: Designable {
    func setupView() {
        self.topLabel.setContentHuggingPriority(.init(251), for: .vertical)
        self.mainLabel.setContentHuggingPriority(.init(250), for: .vertical)
        self.bottomLabel.setContentHuggingPriority(.init(252), for: .vertical)
    }

    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.topLabel,
            self.mainLabel,
            self.hasEventsIndicatorView,
            self.bottomLabel
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(2.5)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-20)
        }

        self.topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
        }

        self.mainLabel.snp.makeConstraints { make in
            make.top.equalTo(self.topLabel.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
        }

        self.hasEventsIndicatorView.snp.makeConstraints { make in
            make.top.equalTo(self.mainLabel.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 4, height: 4))
            self.hasEventsIndicatorViewBottomConstraint = make.bottom.equalToSuperview().offset(-11).constraint
        }

        self.bottomLabel.snp.makeConstraints { make in
            make.top.equalTo(self.mainLabel.snp.bottom).offset(1)
            make.centerX.equalToSuperview()
            self.bottomLabelBottomConstraint = make.bottom.equalToSuperview().offset(-6).constraint
        }
    }
}

