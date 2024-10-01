import UIKit

protocol DetailCalendarViewProtocol: UIViewController {
    func update(with viewModel: CalendarViewModel)
}

final class DetailCalendarViewController: UIViewController, DetailCalendarViewProtocol {
    private lazy var detailCalendarView = self.view as? DetailCalendarView
    private var presenter: DetailCalendarPresenterProtocol

    private var selectedDate = Date()
    private var calendarItems: [CalendarViewModel.CalendarItem] = []
    private var visibleTasks: (today: [CalendarRequestItemViewModel], upcoming: [CalendarRequestItemViewModel]) = ([], [])

	private var expandedCells = [Int: Bool]()
    
    init(presenter: DetailCalendarPresenterProtocol, date: Date) {
        self.presenter = presenter
        selectedDate = date
        super.init(nibName: nil, bundle: nil)
    }
    
    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = DetailCalendarView(frame: UIScreen.main.bounds, date: self.selectedDate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.detailCalendarView?.onMinimizeButtonTap = { [weak self] in self?.dismiss(animated: true) }
        self.detailCalendarView?.onDismiss = { [weak self] in self?.dismiss(animated: true) }
        self.detailCalendarView?.onSelect = { [weak self] date in
            self?.presenter.didSelectDate(date)
        }
        detailCalendarView?.onPageChange = { [weak self] page in
            self?.presenter.didChangePage(page)
        }
        self.presenter.didLoad()
    }
    
    // MARK: - Public
    
    func update(with viewModel: CalendarViewModel) {
		self.calendarItems = viewModel.items

		self.updateTasks(with: viewModel)
		self.updateCalendar(with: viewModel)
    }

	private func updateTasks(with viewModel: CalendarViewModel) {
        if let date = viewModel.selectedDates?.lowerBound {
            selectedDate = date
        }
        displayTasks(scrollToTop: viewModel.shouldScrollItemsToTop)
	}

	private func updateCalendar(with viewModel: CalendarViewModel) {
		self.detailCalendarView?.calendarView.update(with: viewModel)
		self.detailCalendarView?.set(dataSource: self, delegate: self)
	}
    
    // MARK: - Private
	private func displayTasks(scrollToTop: Bool = true) {
        let todayItems = self.calendarItems
            .filter { $0.date.isIn(same: .day, with: selectedDate) }
            .flatMap { $0.tasks }
        
        let upcomingItems = self.calendarItems
            .filter { $0.date.down(to: .day) > selectedDate }
            .flatMap { $0.tasks }
            .sorted { $1.date ?> $0.date }

		let someDataAvailable = todayItems.count + upcomingItems.count > 0
		
		let newVisibleTasks = (today: todayItems, upcoming: upcomingItems)
		
		self.visibleTasks = newVisibleTasks
        self.detailCalendarView?.tableView.reloadData()
        self.detailCalendarView?.tableView.isHidden = !someDataAvailable
        self.detailCalendarView?.emptyStateLabel.isHidden = someDataAvailable

		if scrollToTop, someDataAvailable {
			delay(0.3) {
				self.detailCalendarView?.tableView.scrollToRow(
					at: IndexPath(row: 0, section: 0),
					at: .top,
					animated: true
				)
			}
		}
    }
    
    private func model(at indexPath: IndexPath) -> CalendarRequestItemViewModel? {
        guard indexPath.section == 0 else {
			return self.visibleTasks.upcoming[indexPath.row]
        }
		if self.visibleTasks.today.isEmpty {
			return nil
		}
		return self.visibleTasks.today[indexPath.row]
    }
}

extension DetailCalendarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView: DetailCalendarRequestSectionHeaderView = tableView.dequeueReusableHeaderFooterView() else {
            return nil
        }
        
        let title = sectionTitle(for: section)
        headerView.update(with: title)

        return headerView
    }

    private func sectionTitle(for section: Int) -> String {
        if section != 0 {
            return "fullCalendar.upcomingEvents".localized
        }

        if self.selectedDate.isIn(same: .day, with: Date()) {
            return "fullCalendar.today".localized
        }

        var formatString = "dd MMMM yyyy"
        if self.selectedDate.isIn(same: .year, with: Date()) {
            formatString = "dd MMMM"
        }

        return self.selectedDate.string(formatString)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if !visibleTasks.upcoming.isEmpty {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return max(self.visibleTasks.today.count, 1)
        }
        
        return self.visibleTasks.upcoming.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
		guard let model = self.model(at: indexPath) else {
			let noDataCell = tableView.dequeueReusableCell(for: indexPath) as DetailCalendarNoDataCell
			noDataCell.update(with: "fullCalendar.noEvents".localized)
			return noDataCell
		}

		let eventExpandableCell = tableView.dequeueReusableCell(for: indexPath) as DetailCalendarEventTableViewCell

		let fileModels = self.viewModels(for: model.task.attachedFiles)

		let eventExpandableCellViewModel = DetailCalendarEventTableViewCell.ViewModel(
			event: model, files: fileModels, isExpanded: self.expandedCells[model.task.taskID] ?? false
		)

		eventExpandableCell.onExpand = { [weak self] isExpanded in
			self?.expandedCells[model.task.taskID] = isExpanded
		}

		eventExpandableCell.willChangeSize = { [weak tableView] in
			tableView?.beginUpdates()
		}

		eventExpandableCell.didChangeSize = { [weak tableView] in
			tableView?.endUpdates()
		}

		eventExpandableCell.setup(with: eventExpandableCellViewModel)

		return eventExpandableCell
    }

	private func viewModels(for files: [FilesResponse.File]) -> [DetailCalendarFileView.ViewModel] {
		files.map { file in
			let showsLoader = DocumentsCacheService.shared.url(for: file.cacheKey) == nil

			let fileModel = DetailCalendarFileView.ViewModel(
				title: file.description,
				subtitle: file.fileName,
				leftImage: UIImage(named: "tickets_icon") ?? UIImage(),
				onContentTap: { [weak self] in
					if showsLoader {
						self?.showLoadingIndicator(needsPad: true)
					}

					FileViewerService.shared.viewer(for: file) { vc in
						if showsLoader {
							self?.hideLoadingIndicator()
						}

						if let vc {
							UIViewController.topmostPresented?.present(vc, animated: true)
						}
					}
				},
				onShareTap: {
					FileViewerService.shared.sharing(for: file) { vc in
						if let vc {
							UIViewController.topmostPresented?.present(vc, animated: true)
						}
					}
				}
			)

			return fileModel
		}
	}
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let id = self.model(at: indexPath)?.task.customID {
            self.presenter.openRequest(customID: id)
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.removeTapHandler()
    }
}
