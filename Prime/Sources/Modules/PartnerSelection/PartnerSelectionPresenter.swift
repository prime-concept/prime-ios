import Foundation
import PromiseKit

final class PartnerSelectionPresenter: CatalogItemSelectionPresenterProtocol {
    weak var controller: CatalogItemSelectionControllerProtocol?

    private let qraphQLEndpoint: GraphQLEndpointProtocol
    private var selectedPartnerId: Int?
    private let onSelect: ((Partner) -> Void)
    private var partners: [Partner] = []
    private var filteredPartners: [Partner] = []
	private var partnerTypeId: [Int] = []
	private var search: String = ""

	private lazy var searchDebouncer: Debouncer = {
		let debouncer = Debouncer(timeout: 1.3) { [weak self] in
			self?.performSearch()
		}
		return debouncer
	}()

    init(
        qraphQLEndpoint: GraphQLEndpointProtocol,
		partnerTypeId: [Int],
        selectedPartnerId: Int?,
        onSelect: @escaping ((Partner) -> Void)
    ) {
        self.qraphQLEndpoint = qraphQLEndpoint
		self.partnerTypeId = partnerTypeId
        self.selectedPartnerId = selectedPartnerId
        self.onSelect = onSelect
    }

    func didLoad() {
        self.fetch()
    }

    func search(by string: String) {
		self.partners = []
		self.search = string
		self.searchDebouncer.reset()
	}

	func performSearch() {
		if self.search.isEmpty {
			self.filteredPartners = self.partners
			self.controller?.reload()
			return
		}

		self.fetch(queue: self.search)
	}

    func numberOfItems() -> Int {
        self.filteredPartners.count
    }

    func item(at index: Int) -> CatalogItemRepresentable {
        let partner = self.filteredPartners[index]
        return PartnerViewModel(
			name: partner.name,
			description: partner.address,
            selected: partner.id == self.selectedPartnerId
		)
    }

    func select(at index: Int) {
        self.selectedPartnerId = filteredPartners[index].id
    }

    func apply() {
        self.selectedPartnerId.some { id in
            let partner = self.partners.first { $0.id == id }
            partner.some {
                self.onSelect($0)
            }
        }
    }

    // MARK: - Private

	private func fetch(queue: String? = nil) {
		let completion: ([Partner]) -> Void = { [weak self] partners in
            self.some { (self) in
                self.apply()
                self.filteredPartners = partners
                self.controller?.reload()
                self.controller?.hideLoading()
            }
		}

		guard let queue = queue, !queue.isEmpty else {
			completion([])
			return
		}

		self.controller?.showLoading()
        self.qraphQLEndpoint.request(
            query: GraphQLConstants.partners,
            variables:
				[
					"lang": AnyEncodable(value: Locale.primeLanguageCode),
					"type": AnyEncodable(value: self.partnerTypeId),
					"limit": AnyEncodable(value: 1000),
					"q": AnyEncodable(value: queue)
				]
        ).promise
        .done { [weak self] (response: PartnersResponse) in
			self?.partners = response.partners
			completion(response.partners)
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) Partners fetch failed",
					parameters: error.asDictionary
				)

			AlertPresenter.alertCommonError(error)
            DebugUtils.shared.alert(sender: self, "ERROR FETCH partners \(error)")
        }
    }
}

struct PartnerViewModel: CatalogItemRepresentable {
    let name: String
	let description: String?
    let selected: Bool
}
