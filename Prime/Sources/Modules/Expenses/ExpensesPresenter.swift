import Foundation
import PromiseKit

protocol ExpensesPresenterProtocol: AnyObject {
    func didLoad()
}

final class ExpensesPresenter: ExpensesPresenterProtocol {
    weak var viewController: ExpensesViewControllerProtocol?
    private let profileEndpoint: ProfileEndpointProtocol

	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy/MM"
		return formatter
	}()

    init(profileEndpoint: ProfileEndpointProtocol) {
        self.profileEndpoint = profileEndpoint
    }

    func didLoad() {
		let today = Date()
        self.viewController?.showActivity()

		let promises: [Promise<Transactions>]

		promises = (0...12).compactMap { month in
			Calendar.current.date(byAdding: .month, value: -month, to: today)
		}.map { date in
			let date = dateFormatter.string(from: date)
			return DispatchQueue.global().promise {
				self.profileEndpoint.getExpenses(date: date).promise
			}
		}

		var reducedTransactions = [Transaction]()

		when(fulfilled: promises)
			.done(on: DispatchQueue.main) { transactions in
				reducedTransactions = transactions.reduce([]) {
					$0 + ($1.data.first?.transactions ?? [])
				}
		}.ensure(on: DispatchQueue.main) { [weak self] in
			let viewModel = reducedTransactions.map(ExpensesViewModel.makeAsLoyalty(from:))
			self?.viewController?.update(with: viewModel)
			self?.viewController?.hideActivity()
		}
		.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) Transactions request failed",
					parameters: error.asDictionary
				)
		}
    }
}
