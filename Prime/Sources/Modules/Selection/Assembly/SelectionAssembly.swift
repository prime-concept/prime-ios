import UIKit

final class SelectionAssembly: Assembly {
    private let allowMultipleSelection: Bool
    private let data: TaskCreationFieldViewModel

    private let onSelect: (TaskCreationFieldViewModel) -> Void

    private(set) var scrollView: UIScrollView?

    init(
        data: TaskCreationFieldViewModel,
        allowMultipleSelection: Bool,
        onSelect: @escaping (TaskCreationFieldViewModel) -> Void
    ) {
        self.data = data
        self.allowMultipleSelection = allowMultipleSelection
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let controller = SelectionViewController(
            data: self.data,
            allowMultipleSelection: self.allowMultipleSelection,
            onSelect: self.onSelect
        )
        self.scrollView = controller.scrollView
        return controller
    }
}
