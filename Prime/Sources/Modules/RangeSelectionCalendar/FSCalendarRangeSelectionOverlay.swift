import UIKit
import FSCalendar

class FSCalendarRangeSelectionOverlay: UIView {
	private let calendar: FSCalendar
	private var selectedDates: ClosedRange<Date>? = nil
    var selectionAvailabilityStartDate: Date
	var isMultipleSelectionAllowed: Bool = true
    var isRangeSelectionInProgress = false

	private var map = [(date: Date, frame: CGRect)]()
	private var contentFrame: CGRect? = nil

	private var onSelectionChanged: (ClosedRange<Date>?) -> Void
	private var selectionInProgess: Bool = false

	private var latestDates: ClosedRange<Date>? = nil

	private lazy var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
	private lazy var longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))

	@objc
	private func onLongPress(_ longPressRecognizer: UITapGestureRecognizer) {
		let point = longPressRecognizer.location(in: self)

		switch longPressRecognizer.state {
			case .began:
				self.selectionInProgess = true
				FeedbackGenerator.vibrateSelection()
				self.selectDate(at: point)
			case .ended, .cancelled, .recognized, .failed:
				self.selectionInProgess = false
			default:
				self.selectDate(at: point)
		}
	}

	@objc
	private func onTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
		let point = tapGestureRecognizer.location(in: self)
		self.selectDate(at: point)
	}

	init(
		calendar: FSCalendarView,
        selectionAvailableFrom date: Date = Date(),
		isMultipleSelectionAllowed: Bool = true,
        isLongPressAllowed: Bool = false,
		onSelectionChanged: @escaping (ClosedRange<Date>?) -> Void
	) {
		calendar.isUserInteractionEnabled = false

		self.calendar = calendar.calendar
        self.selectionAvailabilityStartDate = date
		self.onSelectionChanged = onSelectionChanged
		self.isMultipleSelectionAllowed = isMultipleSelectionAllowed

		super.init(frame: .zero)

		self.addGestureRecognizer(self.tapRecognizer)
        if isLongPressAllowed {
            self.addGestureRecognizer(self.longPressRecognizer)
        }
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func updateSelection(_ selectedDate: Date) {
		self.selectedDates = selectedDate.asClosedRange
		self.previousDate ??= self.selectedDates?.lowerBound
		self.updateDatesMap()
		self.highlightSelectedDates()
	}

	func updateSelection(_ selectedDates: ClosedRange<Date>?) {
		self.selectedDates = selectedDates
		self.previousDate ??= selectedDates?.lowerBound
		self.updateDatesMap()
		self.highlightSelectedDates()
	}

	private func highlightSelectedDates() {
		self.subviews.forEach{ $0.removeFromSuperview() }

		guard let dates = self.selectedDates else {
			return
		}

		dates.iterate(by: .day) { date in
			if self.calendar.dateIsFromAnotherMonth(date) {
				return
			}

			let frame = self.map.first{ $0.date == date }?.frame
			guard let frame = frame else {
				return
			}

			self.addSubview(UIView {
				$0.frame = frame
				if date == self.selectedDates?.lowerBound {
					self.markAsLowerBound($0, onlyOneDateSelected: self.selectedDates == date.asClosedRange)
				} else if date == self.selectedDates?.upperBound {
					self.markAsUpperBound($0)
				} else {
					self.markAsIntermediateItem($0)
				}
			})
		}
	}

	private func markAsLowerBound(_ view: UIView, onlyOneDateSelected: Bool) {
		let circle = UIView {
			$0.backgroundColorThemed = Palette.shared.brandPrimary
			$0.layer.cornerRadius = 13
			$0.make(.size, .equal, [26])
		}

		let stripe = UIView {
			$0.backgroundColorThemed = Palette.shared.brandPrimary.withAlphaComponent(0.1)
			$0.make(.height, .equal, 26)
		}

		view.addSubview(stripe)
		view.addSubview(circle)

		circle.make([.centerX, .top], .equalToSuperview)

		stripe.make(.leading, .equal, to: .centerX, of: circle)
		stripe.make([.trailing, .top], .equalToSuperview)

		stripe.isHidden = onlyOneDateSelected
	}

	private func markAsIntermediateItem(_ view: UIView) {
		let stripe = UIView {
			$0.backgroundColorThemed = Palette.shared.brandPrimary.withAlphaComponent(0.1)
			$0.make(.height, .equal, 26)
		}

		view.addSubview(stripe)

		stripe.make([.leading, .trailing, .top], .equalToSuperview)
	}

	private func markAsUpperBound(_ view: UIView) {
		let circle = UIView {
			$0.backgroundColorThemed = Palette.shared.brandPrimary
			$0.layer.cornerRadius = 13
			$0.make(.size, .equal, [26])
		}

		let stripe = UIView {
			$0.backgroundColorThemed = Palette.shared.brandPrimary.withAlphaComponent(0.1)
			$0.make(.height, .equal, 26)
		}

		view.addSubview(stripe)
		view.addSubview(circle)

		circle.make([.centerX, .top], .equalToSuperview)

		stripe.make(.trailing, .equal, to: .centerX, of: circle)
		stripe.make([ .leading, .top], .equalToSuperview)
	}

	private func updateDatesMap() {
		self.map.removeAll()

		guard let firstDay = self.calendar.currentPage.with(.day, 1) else {
			return
		}

		let lastDay = firstDay + 1.months

		(firstDay..<lastDay).iterate(by: .day) { date in
			let frame = self.calendar.frame(for: date)
			self.map.append((date, frame))
		}

		self.contentFrame = nil

		if self.map.isEmpty {
			return
		}

		let sortedMapX = self.map.sorted{ $0.frame.minX < $1.frame.minX }
		let sortedMapY = self.map.sorted{ $0.frame.minY < $1.frame.minY }

		let minX = sortedMapX.first!.frame.minX
		let minY = sortedMapY.first!.frame.minY

		self.contentFrame = CGRect(
			x: minX,
			y: minY,
			width: sortedMapX.last!.frame.maxX - minX,
			height: sortedMapY.last!.frame.maxY - minY
		)
	}

	private var previousDate: Date? = nil

	private func selectDate(at point: CGPoint) {
		guard let date = self.map.first(where: { $0.frame.contains(point) })?.date else {
			return
		}

        if self.calendar.dateIsFromAnotherMonth(date) || date < self.selectionAvailabilityStartDate.down(to: .day) {
			return
		}

		guard self.isMultipleSelectionAllowed,
			  let selectedDates = self.selectedDates else
		{
			self.selectedDates = date.asClosedRange
            self.isRangeSelectionInProgress = true
			self.previousDate = date
			self.onSelectionChanged(self.selectedDates)
			return
		}

		let previousDate = self.previousDate ?? selectedDates.lowerBound

		if self.selectionInProgess {
			if date == selectedDates.lowerBound || date == selectedDates.upperBound {
				self.previousDate = date
				return
			}

			let isDraggingStartDate = previousDate == selectedDates.lowerBound
			let isDraggingEndDate = previousDate == selectedDates.upperBound

			if isDraggingStartDate {
				if date <= selectedDates.upperBound {
					self.selectedDates = date...selectedDates.upperBound
				} else {
					self.selectedDates = selectedDates.upperBound...date
				}
			} else if isDraggingEndDate {
				if selectedDates.lowerBound <= date {
					self.selectedDates = selectedDates.lowerBound...date
				} else {
					self.selectedDates = date...selectedDates.lowerBound
				}
			} else {
				return
			}
		} else {
            if self.isRangeSelectionInProgress {
                if date < selectedDates.lowerBound {
                    self.selectedDates = date...selectedDates.lowerBound
                    self.isRangeSelectionInProgress = false
                } else if date > selectedDates.lowerBound {
                    self.selectedDates = selectedDates.lowerBound...date
                    self.isRangeSelectionInProgress = false
                } else {
                    self.selectedDates = date.asClosedRange
                    self.isRangeSelectionInProgress = true
                }
            } else {
                self.selectedDates = date.asClosedRange
                self.isRangeSelectionInProgress = true
            }
		}

		self.previousDate = date
		self.onSelectionChanged(self.selectedDates)
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		self.contentFrame?.contains(point) ?? false
	}
}

extension FSCalendar {
	func dateIsFromAnotherMonth(_ date: Date) -> Bool {
		let dateMonth = date.down(to: .month)
		let calendarMonth = self.currentPage.down(to: .month)

		if dateMonth < calendarMonth {
			return true
		}

		if calendarMonth + 1.months <= dateMonth {
			return true
		}

		return false
	}
}
