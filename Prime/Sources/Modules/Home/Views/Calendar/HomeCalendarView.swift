import SnapKit
import UIKit

extension HomeCalendarView {
    struct Appearance: Codable {
        var calendarItemSize = CGSize(width: 44, height: 95)
        var calendarMinimumLineSpacing: CGFloat = 0
        var calendarContentInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

        var requestItemSize = CGSize(width: 107, height: 62)
        var requestMinimumLineSpacing: CGFloat = 14
        var requestContentInsets = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 11)

        var expandTintColor = Palette.shared.brandSecondary
    }
}

final class HomeCalendarView: UIView {
	private var visibleDates = [Date]()

	private lazy var mainStackView = with(UIStackView(.vertical)) { stack in
		stack.spacing = 0
		stack.addArrangedSubviews(
			self.calendarCollectionView,
			self.calendarRequestListCollectionView
		)
	}

    private lazy var calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = self.appearance.calendarMinimumLineSpacing
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = Palette.shared.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = self.appearance.calendarContentInsets

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(cellClass: CalendarDayItemCollectionViewCell.self)

        return collectionView
    }()

    private lazy var calendarRequestListCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = self.appearance.requestMinimumLineSpacing
        layout.minimumLineSpacing = self.appearance.requestMinimumLineSpacing
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = Palette.shared.clear
        collectionView.showsHorizontalScrollIndicator = false

		collectionView.contentInset = self.appearance.requestContentInsets
		collectionView.contentOffset.x = -collectionView.contentInset.right

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(cellClass: CalendarRequestItemCollectionViewCell.self)

        collectionView.backgroundView = { () -> UIView in
            let label = UILabel()
            label.attributedTextThemed = Localization.localize("smallCalendar.emptyState").attributed()
                .alignment(.center)
                .primeFont(ofSize: 15, lineHeight: 18)
                .foregroundColor(Palette.shared.gray1)
                .string()

			let view = UIView()
			view.addSubview(label)
			label.make(.hEdges + [.width, .height], .equalToSuperview)
			label.make(.centerY, .equalToSuperview, -11)
            return view
        }()

		collectionView.isHidden = true

        return collectionView
    }()

    private lazy var expandIconView: UIView = {
        let imageView = UIImageView(
            image: UIImage(named: "arrow_down")?.withRenderingMode(.alwaysTemplate)
        )
        imageView.tintColorThemed = self.appearance.expandTintColor
        return imageView.withExtendedTouchArea(insets: UIEdgeInsets(top: 0, left: 30, bottom: 10, right: 30))
    }()

    private lazy var shadowContainerView = ShadowContainerView()

	private(set) lazy var containerView = self.mainStackView

    private let appearance: Appearance

    private var data: [HomeCalendarItemViewModel] = []
    private var visibleTasks: [HomeCalendarItemCellViewModel] = []

    private var selectedIndex = 0
	private var selectedDate = Date()
	private var isDateSelectedByUser = false

    private var isExpanded: Bool = false

    private var expandButtonToCalendarConstraint: Constraint?
    private var expandButtonToCollectionConstraint: Constraint?

    var onExpandButton: ((Date) -> Void)?

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

    func update(with calendarItems: [HomeCalendarItemViewModel]) {
		guard !calendarItems.isEmpty else {
			return
		}

        self.data = calendarItems
        self.calendarCollectionView.reloadData()

		self.selectedIndex = self.isDateSelectedByUser
							 ? self.selectedIndex
							 : calendarItems.firstIndex { $0.dayItemViewModel.isToday } ?? 0

        self.updateRequestList()
    }

	private var layoutIsUpdating = false
	private var userDidManuallyToggleRequestsListVisibility = false

	func updateLayout(shouldMinimize: Bool, mustExpand: Bool = false) {
		self.userDidManuallyToggleRequestsListVisibility = true

		let shouldExpand = !shouldMinimize
		let shouldUpdate = self.isExpanded != shouldExpand

		guard !self.layoutIsUpdating, shouldUpdate else {
			return
		}

		if (shouldExpand || mustExpand) && self.numberOfRequests == 0 {
			return
		}

		self.layoutIsUpdating = true

		self.calendarRequestListCollectionView.toBack()

		self.expandButtonToCalendarConstraint?.update(priority: shouldMinimize ? .high : .low)
		self.expandButtonToCollectionConstraint?.update(priority: shouldMinimize ? .low : .high)

		func animateAlpha(completion: (() -> Void)?) {
			UIView.animate(
				withDuration: 0.125,
				animations: {
					self.calendarRequestListCollectionView.alpha = shouldMinimize ? 0.0 : 1.0
				},
				completion: { _ in
					self.calendarRequestListCollectionView.isHidden = shouldMinimize
					completion?()
				}
			)
		}

		func animatePosition(completion: (() -> Void)?) {
			UIView.animate(
				withDuration: 0.25,
				animations: {
					self.calendarRequestListCollectionView.isHidden = shouldMinimize
					self.superview?.layoutIfNeeded()
				},
				completion: { _ in
					completion?()
				}
			)
		}

		if shouldMinimize {
			animateAlpha {
				animatePosition {
					self.isExpanded = shouldExpand
					self.layoutIsUpdating = false
				}
			}
		} else {
			animatePosition {
				animateAlpha {
					self.isExpanded = shouldExpand
					self.layoutIsUpdating = false
				}
			}
		}
    }

    // MARK: - Private

	private func didTap(on indexPath: IndexPath) {
		FeedbackGenerator.vibrateSelection()

		if self.selectedIndex == indexPath.row {
			self.onExpandButton?(self.visibleMonth)
			return
		}

		self.selectItem(at: indexPath.row)

		delay(0.1) {
			self.updateLayout(shouldMinimize: false, mustExpand: true)
		}
	}

    private func selectItem(at index: Int) {
		self.isDateSelectedByUser = true

        self.selectedIndex = index
		self.selectedDate = self.data[index].dayItemViewModel.date
        self.calendarCollectionView.reloadData()
		self.updateRequestList()
    }

	// TODO вынести эту логику в место, где создается вью-модель
	private func updateVisibleTasks() {
		guard let selectedDayViewModel = self.data[safe: self.selectedIndex] else {
			return
		}

		var tasksToShow = selectedDayViewModel.items

		var borrowCount = 5 - tasksToShow.count
		var nextDayIndex = self.selectedIndex + 1

		while borrowCount > 0 {
			if nextDayIndex >= self.data.count {
				break
			}

			guard let borrowedTasks = self.data[safe: nextDayIndex]?.items.prefix(borrowCount) else {
				break
			}

			borrowCount -= borrowedTasks.count
			tasksToShow.append(contentsOf: borrowedTasks)
			nextDayIndex += 1
		}

		self.visibleTasks = tasksToShow.map { item in
			HomeCalendarItemCellViewModel(
				dayItemViewModel: selectedDayViewModel.dayItemViewModel,
				item: item
			)
		}
	}

	private var numberOfRequests: Int {
		self.collectionView(
			self.calendarRequestListCollectionView,
			numberOfItemsInSection: 0
		)
	}

	private func updateRequestList() {
        self.updateVisibleTasks()
        self.calendarRequestListCollectionView.reloadKeepingOffsetX()

		with(self.calendarRequestListCollectionView) { view in
			view.backgroundView?.alpha = numberOfRequests == 0 ? 1 : 0
			view.alpha = 1

			if !self.userDidManuallyToggleRequestsListVisibility {
				view.isHidden = numberOfRequests == 0
			}
		}
    }

	private var visibleMonth: Date {
		if self.visibleDates.isEmpty {
			return Date()
		}

		if self.visibleDates.contains(where: { date in
			date.isIn(same: .day, with: self.selectedDate)
		}) {
			return self.selectedDate
		}

		let datesByMonths = Dictionary(grouping: self.visibleDates) { date in
			Calendar.current.component(.month, from: date)
		}.sorted { first, second in
			first.value.count > second.value.count
		}
		
		let mostRepresentedMonthDate = datesByMonths.sorted { first, second in
			first.value.count > second.value.count
		}.first?.value.first ?? Date()

		if mostRepresentedMonthDate.isIn(same: .month, with: self.selectedDate) {
			return self.selectedDate
		}

		return mostRepresentedMonthDate
	}
}

extension HomeCalendarView: Designable {
    func setupView() {
        self.expandIconView.addTapHandler { [weak self] in
			self.some { (self) in
				self.onExpandButton?(self.visibleMonth)
			}
        }
    }

    func addSubviews() {
        [
            self.shadowContainerView,
            self.containerView,
            self.expandIconView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.shadowContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.containerView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
        }

        self.calendarCollectionView.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.calendarItemSize.height)
        }

        self.calendarRequestListCollectionView.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.requestItemSize.height)
        }

        self.expandIconView.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.bottom.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()

            self.expandButtonToCalendarConstraint = make.top
                .equalTo(self.calendarCollectionView.snp.bottom)
                .offset(-28)
                .priority(.low)
                .constraint
            self.expandButtonToCollectionConstraint = make.top
                .equalTo(self.calendarRequestListCollectionView.snp.bottom)
                .offset(-17)
                .priority(.high)
                .constraint
        }
    }
}

extension HomeCalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        switch collectionView {
        case self.calendarCollectionView:
            return self.data.count

        case self.calendarRequestListCollectionView:
            if self.data.isEmpty {
                return 0
            }
            return self.visibleTasks.count

        default:
            return 0
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch collectionView {
        case self.calendarCollectionView:
            let cell: CalendarDayItemCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            if let item = self.data[safe: indexPath.row] {
                cell.setup(with: item.dayItemViewModel)
                cell.set(state: item.dayItemViewModel.hasEvents ? .withEvents : .withoutEvents)

                if self.selectedIndex == indexPath.row {
                    cell.set(state: .selected)
                }
            }

            return cell

        case self.calendarRequestListCollectionView:
            let cell: CalendarRequestItemCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            let item = self.visibleTasks[indexPath.row].item
            cell.setup(with: item)
            return cell

        default:
            fatalError("Unimplemented collection view")
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if collectionView === self.calendarCollectionView {
			self.data[safe: indexPath.row].some { model in
				self.visibleDates.append(model.dayItemViewModel.date)
			}

            cell.addTapHandler { [weak self] in
				self?.didTap(on: indexPath)
            }
		} else if collectionView == self.calendarRequestListCollectionView {
			let task = self.visibleTasks[indexPath.row].item.task
			cell.addTapHandler {
				var userInfo: [String: Any] = [:]
				userInfo["task"] = task
				userInfo["taskId"] = task?.taskID
				Notification.post(.didTapOnTaskMessage, userInfo: userInfo)
			}
		}
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
		if collectionView === self.calendarCollectionView {
			self.data[safe: indexPath.row].some { model in
				self.visibleDates.removeAll {
					$0 == model.dayItemViewModel.date
				}
			}
		}
        cell.removeTapHandler()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
	) -> CGSize {
		switch collectionView {
			case self.calendarCollectionView:
				return self.appearance.calendarItemSize

			case self.calendarRequestListCollectionView:
				guard let viewModel = self.visibleTasks[safe: indexPath.row]?.item else {
					return .zero
				}

            let fullWidth = collectionView.bounds.width / 1.5
				- self.appearance.requestContentInsets.left
				- self.appearance.requestMinimumLineSpacing
				- self.appearance.requestContentInsets.right

				let cell = CalendarRequestItemCollectionViewCell.reference
				cell.setup(with: viewModel)
				let cellHeight = self.appearance.requestItemSize.height
				let cellWidth = min(fullWidth, cell.sizeFor(height: cellHeight).width)

				return CGSize(width: cellWidth, height: cellHeight)

			default:
				fatalError("Unimplemented collection view")
		}
	}
}
