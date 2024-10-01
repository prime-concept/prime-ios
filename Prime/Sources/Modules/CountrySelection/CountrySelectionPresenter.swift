import Foundation
import PromiseKit

final class CountrySelectionPresenter: CatalogItemSelectionPresenterProtocol {
    weak var controller: CatalogItemSelectionControllerProtocol?

    private let qraphQLEndpoint: GraphQLEndpointProtocol
    private var selectedCountry: Country?
    private let onSelect: ((Country) -> Void)
    private var countries: [Country] = []
    private var filteredCountries: [Country] = []
    private var search: String?

    init(
        qraphQLEndpoint: GraphQLEndpointProtocol,
        selectedCountry: Country?,
        onSelect: @escaping ((Country) -> Void)
    ) {
        self.qraphQLEndpoint = qraphQLEndpoint
        self.selectedCountry = selectedCountry
        self.onSelect = onSelect
    }

    func didLoad() {
        self.fetch()
    }

    func search(by string: String) {
        self.search = string

        if string.isEmpty {
            self.filteredCountries = self.countries
        } else {
            self.filteredCountries = self.countries.filter {
                $0.name.range(of: string, options: .caseInsensitive) != nil
            }
        }
        self.controller?.reload()
    }

    func numberOfItems() -> Int {
        self.filteredCountries.count
    }

    func item(at index: Int) -> CatalogItemRepresentable {
        let country = self.filteredCountries[index]
        return CountryViewModel(name: country.name, selected: country == self.selectedCountry )
    }

    func select(at index: Int) {
        self.selectedCountry = filteredCountries[index]
    }

    func apply() {
        self.selectedCountry.flatMap { self.onSelect($0) }
    }

    // MARK: - Private

    private func fetch() {
        self.qraphQLEndpoint.request(
            query: GraphQLConstants.countries,
            variables: [
				"lang": AnyEncodable(value: Locale.primeLanguageCode)
			]
        ).promise
        .done { [weak self] (response: Countries) in
            guard let self = self else {
                return
            }

            self.countries = response.countries.filter {
                $0.code != nil
            }
            self.filteredCountries = self.countries
            self.normalizeSelectedCountry()
            self.controller?.reload()
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) Countries fetch failed",
					parameters: error.asDictionary
				)
			AlertPresenter.alertCommonError(error)
            DebugUtils.shared.alert(sender: self, "ERROR FETCH COUNTRIES \(error)")
        }
    }

    private func normalizeSelectedCountry() {
        guard let fakeCountry = self.selectedCountry, fakeCountry.id == -1 else {
            return
        }

        self.selectedCountry = self.countries.first { country in
            country.code == fakeCountry.code || country.name == fakeCountry.name
        }
    }
}

struct CountryViewModel {
    let name: String
    let selected: Bool
}

extension CountryViewModel: CatalogItemRepresentable {
	var description: String? {
		nil
	}
}
