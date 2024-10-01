import UIKit

final class ContactTypeSelectionAssembly: Assembly {
    private let data: [ContactTypeViewModel]
    private let onSelect: (ContactTypeViewModel) -> Void
    private(set) var scrollView: UIScrollView?

    init(
        data: [ContactTypeViewModel],
        onSelect: @escaping (ContactTypeViewModel) -> Void
    ) {
        self.data = data
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let controller = ContactTypeSelectionViewController(
            with: self.data,
            onSelect: self.onSelect
        )
        self.scrollView = controller.scrollView
        return controller
    }
}
