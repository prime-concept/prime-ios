import FSCalendar
import UIKit

extension FSCalendarRangeSelectionViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5

        var buttonCornerRadius: CGFloat = 8

        var doneButtonTextColor = Palette.shared.gray5
        var doneButtonBackgroundColor = Palette.shared.brandPrimary

        var resetButtonBorderColor = Palette.shared.gray3
		var resetButtonBorderWidth: CGFloat = 1
        var resetButtonTextColor = Palette.shared.danger
    }
}

final class FSCalendarRangeSelectionViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.contentInset = .init(top: -10, left: 0, bottom: 50, right: 0)
        tableView.backgroundColorThemed = self.appearance.backgroundColor
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.register(cellClass: FSCalendarRangeSelectionCell.self)
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        return tableView
    }()

    private lazy var buttonsStackView: UIStackView = {
        let buttonStack = UIStackView(arrangedSubviews: [self.resetButton, self.doneButton])
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 5
        return buttonStack
    }()

    private lazy var resetButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("form.reset")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.resetButtonTextColor)
            .string()

        label.clipsToBounds = true
        label.layer.cornerRadius = self.appearance.buttonCornerRadius

        label.layer.borderColorThemed = self.appearance.resetButtonBorderColor
		label.layer.borderWidth = self.appearance.resetButtonBorderWidth / UIScreen.main.scale

        label.addTapHandler(feedback: .scale) { [weak self] in
            guard let self = self else {
                return
            }
            self.deselectDates()
            self.setDoneButton(enabled: false)
        }

        return label
    }()

    private lazy var doneButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("form.done")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.doneButtonTextColor)
            .string()

        label.backgroundColorThemed = self.appearance.doneButtonBackgroundColor
        label.clipsToBounds = true
        label.layer.cornerRadius = self.appearance.buttonCornerRadius

        label.addTapHandler(feedback: .scale) { [weak self] in
            self?.selectionHandler(self?.selectedDates)
            self?.dismiss(animated: true)
        }

        return label
    }()

	private let months: [Date]
	private var isMultipleSelectionAllowed: Bool
	private let selectionHandler: (ClosedRange<Date>?) -> Void
	private var selectedDates: ClosedRange<Date>?
    private let selectionAvailabilityStartDate: Date

    private let appearance: Appearance

	init(
        appearance: Appearance = Theme.shared.appearance(),
		monthCount: Int,
        selectionAvailableFrom date: Date = Date(),
		isMultipleSelectionAllowed: Bool = true,
		selectedDates: ClosedRange<Date> = (Date()...(Date() + 1.days)).down(to: .day),
		selectionHandler: @escaping (ClosedRange<Date>?) -> Void
	) {
        self.appearance = appearance

		let currentMonth = Date().down(to: .month)
		self.months = (0..<monthCount).compactMap { currentMonth + $0.months }
        self.selectionAvailabilityStartDate = date
		self.isMultipleSelectionAllowed = isMultipleSelectionAllowed

		self.selectionHandler = selectionHandler

		super.init(nibName: nil, bundle: nil)
		self.selectedDates = selectedDates.down(to: .day)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }

    // MARK: - Helpers

    private func setupView() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor

        let grabberView = GrabberView(appearance: .init(height: 3))

        [
            grabberView,
            self.tableView,
            self.buttonsStackView
        ].forEach(self.view.addSubview)
        
        [
            self.resetButton,
            self.doneButton
        ].forEach { view in
            view.snp.makeConstraints { make in
                make.height.equalTo(44)
            }
        }

        grabberView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 35, height: 3))
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }

        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(7)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.buttonsStackView.snp.top).offset(-20)
        }

        self.buttonsStackView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(44)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }

    private func deselectDates() {
        self.selectedDates = nil
        self.tableView.visibleCells
            .compactMap { $0 as? FSCalendarRangeSelectionCell }
            .forEach { cell in
                cell.update(with: .init(
                    selectionAvailableFrom: self.selectionAvailabilityStartDate,
                    selectedDates: self.selectedDates,
                    isMultipleSelectionAllowed: self.isMultipleSelectionAllowed)
                )
            }
    }

    private func setDoneButton(enabled: Bool) {
        self.doneButton.isUserInteractionEnabled = enabled

        UIView.animate(withDuration: 0.5) {
            self.doneButton.alpha = enabled ? 1.0 : 0.5
        }
    }
}

extension FSCalendarRangeSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.months.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FSCalendarRangeSelectionCell = tableView.dequeueReusableCell(for: indexPath)
        cell.isExclusiveTouch = true

        let month = self.months[indexPath.row]
        cell.update(with: .init(
            month: month,
            selectionAvailableFrom: self.selectionAvailabilityStartDate,
            selectedDates: self.selectedDates,
            isMultipleSelectionAllowed: self.isMultipleSelectionAllowed)
        )

        cell.onSelectionChanged ??= { [weak self] dates in
            guard let self = self else {
                return
            }
            self.selectedDates = dates
            tableView.visibleCells
                .compactMap { $0 as? FSCalendarRangeSelectionCell }
                .forEach { cell in
                    cell.update(with: .init(
                        selectionAvailableFrom: self.selectionAvailabilityStartDate,
                        selectedDates: dates,
                        isMultipleSelectionAllowed: self.isMultipleSelectionAllowed)
                    )
                }

            self.setDoneButton(enabled: true)
        }

        return cell
    }
}
