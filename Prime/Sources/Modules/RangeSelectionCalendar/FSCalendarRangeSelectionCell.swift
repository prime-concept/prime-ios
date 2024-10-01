import UIKit
import FSCalendar

extension FSCalendarRangeSelectionCell {
	struct Appearance: Codable {
		var borderSelectionColor = Palette.shared.clear
		var titleSelectionColor = Palette.shared.gray5
		var otherMonthDatesColor = Palette.shared.clear
		var datesInThePastColor = Palette.shared.gray1
	}
}

class FSCalendarRangeSelectionCell: UITableViewCell, Reusable {
	struct ViewModel {
        init(
            month: Date? = nil,
            selectionAvailableFrom date: Date,
            selectedDates: ClosedRange<Date>?,
            isMultipleSelectionAllowed: Bool
        ) {
            self.month = month
            self.selectionAvailabilityStartDate = date
            self.selectedDates = selectedDates
            self.isMultipleSelectionAllowed = isMultipleSelectionAllowed
        }

		let month: Date?
		let selectedDates: ClosedRange<Date>?
		let isMultipleSelectionAllowed: Bool
        let selectionAvailabilityStartDate: Date
	}

	var appearance: Appearance = Theme.shared.appearance()
	var onSelectionChanged: ((ClosedRange<Date>?) -> Void)? = nil
    private var selectionAvailabilityStartDate: Date = Date()
	private var selectedDates: ClosedRange<Date>? = nil

	private(set) lazy var calendarView = FSCalendarView(
		appearance:
				.init(
					borderSelectionColor: appearance.borderSelectionColor,
					titleSelectionColor: appearance.titleSelectionColor
				)
	)

	private lazy var highlighter = FSCalendarRangeSelectionOverlay(calendar: self.calendarView) { [weak self] dates in
		self?.onSelectionChanged?(dates)
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.calendarView.calendar.allowsMultipleSelection = true
		self.calendarView.calendar.delegate = self
		self.calendarView.calendar.placeholderType = .none

		self.contentView.addSubview(self.highlighter)
		self.contentView.addSubview(self.calendarView)

		self.calendarView.make(.edges, .equalToSuperview, priorities: [.defaultHigh])
		self.highlighter.make(.edges, .equalToSuperview)
		self.highlighter.isExclusiveTouch = true
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update(with viewModel: ViewModel) {
		// For some reason Calendar does not load provided currentPage
		// when loaded synchronously
		delay(0.1) {
			self.calendarView.calendar.selectedDates.forEach { date in
				self.calendarView.calendar.deselect(date)
			}

			let month = viewModel.month ?? self.calendarView.calendar.currentPage

			self.calendarView.update(with: CalendarViewModel(
				currentPage: month,
				selectedDates: viewModel.selectedDates,
				isScopeSelectionEnabled: false,
				isMultipleSelectionAllowed: viewModel.isMultipleSelectionAllowed
			))

			self.selectedDates = viewModel.selectedDates

			if let selectedDates = viewModel.selectedDates {
				self.calendarView.calendar.select(selectedDates.lowerBound, scrollToDate: false)

				if viewModel.isMultipleSelectionAllowed {
					self.calendarView.calendar.select(selectedDates.upperBound, scrollToDate: false)
                    self.highlighter.isRangeSelectionInProgress = selectedDates.lowerBound == selectedDates.upperBound
				}
			}

			self.highlighter.isMultipleSelectionAllowed = viewModel.isMultipleSelectionAllowed
			self.highlighter.updateSelection(viewModel.selectedDates)

            self.selectionAvailabilityStartDate = viewModel.selectionAvailabilityStartDate
            self.highlighter.selectionAvailabilityStartDate = viewModel.selectionAvailabilityStartDate
            self.calendarView.calendar.reloadData()
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		self.highlighter.updateSelection(nil)
	}
}

extension FSCalendarRangeSelectionCell: FSCalendarDelegateAppearance {
	func calendar(_ calendar: FSCalendar, shouldDeselect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
		false
	}

	func calendar(
		_ calendar: FSCalendar,
		appearance: FSCalendarAppearance,
		titleDefaultColorFor date: Date
	) -> UIColor? {
		if calendar.dateIsFromAnotherMonth(date) {
			return self.appearance.otherMonthDatesColor.rawValue
		}

        if date.down(to: .day) < self.selectionAvailabilityStartDate.down(to: .day) {
			return self.appearance.datesInThePastColor.rawValue
		}

		return calendar.appearance.titleDefaultColor
	}
}


