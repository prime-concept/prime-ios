import FSCalendar
import UIKit

extension DetailCalendarView {
    struct Appearance: Codable {
        var separatorColor = Palette.shared.gray3

        var minimizeIconTintColor = Palette.shared.brandSecondary

        var emptyFont = Palette.shared.primeFont.with(size: 15)
        var emptyTextColor = Palette.shared.gray1
    }
}

final class DetailCalendarView: UIView {
    private lazy var backgroundBlurView = Self.makeBackgroundBlurView()
    private(set) lazy var shadowContainerView = ShadowContainerView()
    private(set) lazy var contentContainerView = UIView()

	private(set) lazy var calendarView = FSCalendarView(selectedDates: self.date.asClosedRange)
    private lazy var topSeparatorView = self.makeSeparatorView()

    private(set) lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.emptyFont
        label.textColorThemed = self.appearance.emptyTextColor
        // swiftlint:disable:next prime_font
        label.text = Localization.localize("fullCalendar.emptyState")
		label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private(set) lazy var tableView: UITableView = {
		let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColorThemed = Palette.shared.clear
		tableView.separatorColor = .clear
		tableView.allowsSelection = true
        tableView.separatorStyle = .none

		tableView.tableHeaderView = UIView { $0.make(.height, .equal, 0.1) }
		tableView.tableFooterView = UIView { $0.make(.height, .equal, 0.1) }

		tableView.register(cellClass: DetailCalendarNoDataCell.self)
        tableView.register(cellClass: DetailCalendarEventTableViewCell.self)
		tableView.register(headerFooterClass: DetailCalendarRequestSectionHeaderView.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 1000
		tableView.sectionHeaderHeight = 35
		tableView.sectionFooterHeight = 0.1

		if #available(iOS 15.0, *) {
			tableView.isPrefetchingEnabled = false
		}
		
        return tableView
    }()

    private let appearance: Appearance
	private var date: Date
    private var page: Date

    var onMinimizeButtonTap: (() -> Void)?
    var onSelect: ((Date) -> Void)?
    var onPageChange: ((Date) -> Void)?
	var onDismiss: (() -> Void)?

	init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance(), date: Date) {
        self.appearance = appearance
		self.date = date
        self.page = date.down(to: .month)
        super.init(frame: frame)

        self.addGrabberView()
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func makeBackgroundBlurView() -> UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
		view.backgroundColorThemed = Palette.shared.custom_lightGray2.withAlphaComponent(0.5)
        return view
    }

    private func makeSeparatorView() -> UIView {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }

    func set(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
        self.tableView.dataSource = dataSource
        self.tableView.delegate = delegate
        self.tableView.reloadData()
    }
    
    private func addGrabberView() {
        let grabberView = UIView()
        grabberView.layer.cornerRadius = 2
        grabberView.backgroundColorThemed = Palette.shared.gray3
        self.calendarView.addSubview(grabberView)
        grabberView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 36, height: 4))
            make.top.equalToSuperview().offset(-5)
        }
        self.bringSubviewToFront(grabberView)
    }
}

extension DetailCalendarView: Designable {
    func setupView() {
        self.calendarView.onSelect = { [weak self] date in
			if let oldMonth = self?.date.down(to: .month) {
				let newMonth = date.down(to: .month)
				if newMonth != oldMonth {
					self?.calendarView.setCurrentPage(newMonth)
				}
			}

			self?.date = date
			self?.tableView.reloadData()
            self?.onSelect?(date)
        }

        calendarView.onPageChange = { [weak self] date in
            self?.onPageChange?(date)
        }

		self.backgroundBlurView.addTapHandler(feedback: .none) { [weak self] in
			self?.onDismiss?()
		}
    }

    func addSubviews() {
        [
            self.backgroundBlurView,
            self.shadowContainerView
        ].forEach(self.addSubview)

        self.shadowContainerView.addSubview(self.contentContainerView)
        [
            self.calendarView,
            self.topSeparatorView,
            self.tableView
        ].forEach(self.contentContainerView.addSubview)

		self.addSubview(self.emptyStateLabel)
    }

    func makeConstraints() {
        self.backgroundBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.shadowContainerView.snp.makeConstraints { make in
			make.top.equalTo(self.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        self.contentContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.calendarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview()
        }

        self.topSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(self.calendarView.snp.bottom)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-12)
        }

        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.topSeparatorView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

		self.emptyStateLabel.snp.makeConstraints { make in
			make.top.equalTo(self.topSeparatorView.snp.bottom)
			make.leading.trailing.equalToSuperview().inset(15)
			make.bottom.equalToSuperview()
		}
    }
}
