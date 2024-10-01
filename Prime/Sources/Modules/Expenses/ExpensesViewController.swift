import Foundation
import UIKit
import SnapKit

protocol ExpensesViewControllerProtocol: AnyObject {
    func update(with expenses: [ExpensesViewModel])
    func showActivity()
    func hideActivity()
}

final class ExpensesViewController: UIViewController {
    private let presenter: ExpensesPresenterProtocol
    private lazy var datesSorted: [Date] = []
    private lazy var expensesByDate: [Date: [ExpensesViewModel]] = [:]

	private lazy var grabberView = with(UIView()) { view in
		view.backgroundColorThemed = Palette.shared.gray3
		view.layer.cornerRadius = 1.5
	}

	private lazy var noDataView = with(ExpensesNoDataView()) { view in
		view.isHidden = true
	}

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
		tableView.backgroundColorThemed = Palette.shared.gray5
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(
            ExpensesTableViewCell.self,
            forCellReuseIdentifier: ExpensesTableViewCell.defaultReuseIdentifier
        )
        tableView.register(
            ExpensesHeader.self,
            forHeaderFooterViewReuseIdentifier: ExpensesHeader.defaultReuseIdentifier
        )

        return tableView
    }()

    init(presenter: ExpensesPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColorThemed = Palette.shared.gray5
		self.setupSubviews()
        self.presenter.didLoad()
    }

    func setupSubviews() {
        self.view.addSubview(self.tableView)
		self.view.addSubview(self.noDataView)

        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

		self.noDataView.make(.edges, .equal, to: self.view.safeAreaLayoutGuide)

		self.view.addSubview(self.grabberView)
		self.grabberView.snp.makeConstraints { make in
			make.top.equalToSuperview().offset(10)
			make.centerX.equalToSuperview()
			make.width.equalTo(35)
			make.height.equalTo(3)
		}
    }

    private func groupByMonths(_ expenses: [ExpensesViewModel]) -> [Date: [ExpensesViewModel]] {
        let expensesByMonths: [Date: [ExpensesViewModel]] = [:]
        return expenses.reduce(into: expensesByMonths) { acc, cur in
            let components = Calendar.current.dateComponents([.year, .month, .day], from: cur.date ?? Date())
            let date = Calendar.current.date(from: components) ?? Date()
            let existing = acc[date] ?? []
            acc[date] = existing + [cur]
        }
    }
}

extension ExpensesViewController: ExpensesViewControllerProtocol {
    func showActivity() {
		self.view.showLoadingIndicator()
    }

    func hideActivity() {
        HUD.find(on: self.view)?.remove()
    }

    func update(with expenses: [ExpensesViewModel]) {
		let expensesByMonths = self.groupByMonths(expenses)
        self.expensesByDate.merge(expensesByMonths) { (_, new) in new }
        self.datesSorted = Array(expensesByDate.keys).sorted(by: >)
		self.tableView.reloadData()

		self.tableView.isHidden = expenses.isEmpty
		self.noDataView.isHidden = !self.tableView.isHidden
    }
}

extension ExpensesViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		self.datesSorted.count
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		self.expensesByDate[datesSorted[section]]?.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: ExpensesTableViewCell.defaultReuseIdentifier,
			for: indexPath
		) as? ExpensesTableViewCell else {
			return UITableViewCell()
		}
		guard let value = self.expensesByDate[datesSorted[indexPath.section]] else {
			return cell
		}
		cell.setup(with: value[indexPath.row])
		return cell
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let view = tableView.dequeueReusableHeaderFooterView(
			withIdentifier: ExpensesHeader.defaultReuseIdentifier
		) as? ExpensesHeader
		view?.setDateTitle(date: self.datesSorted[section])
		return view
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		10
	}
}
