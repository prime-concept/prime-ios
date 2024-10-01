import UIKit

final class CountryCodesAssembly: Assembly {
    private let countryCode: CountryCode
    private let onSelect: (CountryCode) -> Void

    private(set) var scrollView: UIScrollView?

    init(countryCode: CountryCode, onSelect: @escaping (CountryCode) -> Void) {
        self.countryCode = countryCode
        self.onSelect = onSelect
    }
    func make() -> UIViewController {
        let controller = CountryCodesViewController(
            countryCode: self.countryCode,
            onSelect: onSelect
        )
        self.scrollView = controller.scrollView
        return controller
    }
}
