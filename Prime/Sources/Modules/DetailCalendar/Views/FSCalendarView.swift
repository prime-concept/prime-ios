import FSCalendar
import UIKit

extension FSCalendarView {
    struct Appearance: Codable {
        var weekdayTextColor = Palette.shared.gray0
        var weekdayFont = Palette.shared.primeFont.with(size: 16)

        var weekendTextColor = Palette.shared.gray2

        var titleDefaultColor = Palette.shared.gray0
        var titleFont = Palette.shared.primeFont.with(size: 14)

        var borderSelectionColor = Palette.shared.gray0
        var selectionColor = Palette.shared.clear
        var titleSelectionColor = Palette.shared.gray0

        var titleTodayColor = Palette.shared.brandSecondary
        var todayColor = Palette.shared.clear

        var eventSelectionColor = Palette.shared.clear
        var eventDefaultColor = Palette.shared.brandSecondary
    }
}

extension FSCalendar {
    func customizeCalenderAppearance(with appearance: FSCalendarView.Appearance) {
		self.appearance.weekdayTextColor = appearance.weekdayTextColor.rawValue
		self.appearance.weekdayFont = appearance.weekdayFont.rawValue

        self.appearance.titleDefaultColor = appearance.titleDefaultColor.rawValue
		self.appearance.titleFont = appearance.titleFont.rawValue

        self.appearance.borderSelectionColor = appearance.borderSelectionColor.rawValue
        self.appearance.selectionColor = appearance.selectionColor.rawValue
        self.appearance.titleSelectionColor = appearance.titleSelectionColor.rawValue

        self.appearance.titleTodayColor = appearance.titleTodayColor.rawValue
        self.appearance.todayColor = appearance.todayColor.rawValue

        self.appearance.eventSelectionColor = appearance.eventSelectionColor.rawValue
        self.appearance.eventDefaultColor = appearance.eventDefaultColor.rawValue

        self.appearance.titleWeekendColor = appearance.weekendTextColor.rawValue

        do {
            let weekdaysContentView = self.calendarWeekdayView.subviews[safe: 0]

            let weekends: [Int] = [1, 7] // Sunday, Saturday
            let startOfWeekday = Int(self.firstWeekday)
            let normWeekends = weekends.map { num -> Int in
                var x = num - startOfWeekday + 1
                if x <= 0 { x += 7 }
                return x
            }

            for (idx, weekdayLabel) in (weekdaysContentView?.subviews ?? []).enumerated() {
                if normWeekends.contains(idx + 1) {
                    (weekdayLabel as? UILabel)?.textColorThemed = appearance.weekendTextColor
                }
            }
        }

        self.appearance.eventOffset = .init(x: 0, y: -4)
    }
}

final class FSCalendarView: UIView {
    private static var minimumDate = Calendar.current.startOfDay(for: Date())

    private lazy var headerView = DetailCalendarHeaderView()

    private(set) lazy var calendar: FSCalendar = {
        let calendar = FSCalendar(frame: .zero)
		calendar.appearance.weekdayFont = self.appearance.weekdayFont.rawValue
        calendar.dataSource = self
        calendar.delegate = self

        calendar.locale = Locale.current
        calendar.firstWeekday = UInt(Calendar.current.firstWeekday)

        calendar.calendarHeaderView.isHidden = true
        calendar.customizeCalenderAppearance(with: self.appearance)

		Notification.onReceive(.paletteDidChange) { [weak self] _ in
			guard let self = self else { return }
			calendar.customizeCalenderAppearance(with: self.appearance)
		}

        return calendar
    }()

    private let appearance: Appearance

	private var data: [CalendarViewModel.CalendarItem] = []

	private var currentPage: Date = Date().down(to: .month)
	private var selectedDates: ClosedRange<Date>?

    var onSelect: ((Date) -> Void)?
    var onPageChange: ((Date) -> Void)?

	init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance(), selectedDates: ClosedRange<Date> = .today) {
        self.appearance = appearance
		self.selectedDates = selectedDates
		
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	func update(with viewModel: CalendarViewModel) {
		self.data = viewModel.items

		self.headerView.set(date: viewModel.currentPage)
		self.headerView.leftButton.isHidden = !viewModel.isScopeSelectionEnabled
		self.headerView.rightButton.isHidden = !viewModel.isScopeSelectionEnabled

		self.currentPage = viewModel.currentPage
		self.selectedDates = viewModel.selectedDates

		self.calendar.allowsMultipleSelection = viewModel.isMultipleSelectionAllowed
		self.calendar.scrollEnabled = viewModel.isScopeSelectionEnabled
		self.calendar.pagingEnabled = viewModel.isScopeSelectionEnabled

		if let dateToSelect = self.dateToSelect(from: viewModel.selectedDates) {
			if dateToSelect != self.calendar.selectedDate {
				self.calendar.select(dateToSelect)
				self.calendar.reloadData()
			}
		} else {
			if let date = self.calendar.selectedDate {
				self.calendar.deselect(date)
			}
		}

		self.calendar.currentPage = self.currentPage
	}

	private func dateToSelect(from newDates: ClosedRange<Date>?) -> Date? {
		guard let newDates = newDates else {
			return nil
		}

		guard let oldDates = self.selectedDates else {
			return newDates.lowerBound
		}

		if newDates.lowerBound < oldDates.lowerBound {
			return newDates.lowerBound
		}

		if newDates.upperBound > oldDates.upperBound {
			return newDates.upperBound
		}

		var date = self.calendar.selectedDate ?? oldDates.lowerBound
		date = date.down(to: .day)

		return date
	}

	public func setCurrentPage(_ date: Date) {
		self.currentPage = date
		self.headerView.set(date: self.currentPage)
		self.calendar.currentPage = self.currentPage
	}
}

extension FSCalendarView: FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        for item in self.data where item.date.isEqual(with: date) {
            return item.tasks.isEmpty ? 0 : 1
        }
        return 0
    }

    func calendar(
        _ calendar: FSCalendar,
        didSelect date: Date,
        at monthPosition: FSCalendarMonthPosition
    ) {
        self.onSelect?(date)
    }

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        self.headerView.set(date: calendar.currentPage)
        onPageChange?(calendar.currentPage)
    }

    func calendar(
        _ calendar: FSCalendar,
        willDisplay cell: FSCalendarCell,
        for date: Date,
        at monthPosition: FSCalendarMonthPosition
    ) {
		switch monthPosition {
			case .next, .previous:
				cell.titleLabel.alpha = 0.2
				cell.eventIndicator.alpha = 0.2
			default:
				cell.titleLabel.alpha = 1.0
				cell.eventIndicator.alpha = 1.0
		}
    }
}

extension FSCalendarView: Designable {
    func setupView() {
        self.headerView.set(date: self.currentPage)
        self.headerView.changeMonth = { [weak self] isForward in
            guard let strongSelf = self else {
                return
            }
			
			let targetDate = strongSelf.currentPage + (isForward ? 1 : -1).months

			strongSelf.setCurrentPage(targetDate)
			strongSelf.headerView.set(date: targetDate)
        }
    }

    func addSubviews() {
        [self.calendar, self.headerView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.headerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
        }

        self.calendar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(23)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(269)
            make.bottom.equalToSuperview()
        }
    }
}
