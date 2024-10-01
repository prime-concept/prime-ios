import UIKit

final class SelectionViewController: UIViewController {
    private lazy var selectionView = self.view as? SelectionView

    private let allowMultipleSelection: Bool
    private let data: TaskCreationFieldViewModel
    private let name: String

    private let onSelect: (TaskCreationFieldViewModel) -> Void

    var scrollView: UIScrollView? {
        self.selectionView?.collectionView
    }

    init(
        data: TaskCreationFieldViewModel,
        allowMultipleSelection: Bool,
        onSelect: @escaping (TaskCreationFieldViewModel) -> Void
    ) {
        self.data = data
        self.name = data.input.fieldName
        self.allowMultipleSelection = allowMultipleSelection
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = SelectionView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.selectionView?.setup(
            with: self.data,
            allowMultipleSelection: self.allowMultipleSelection
        )

        self.selectionView?.onApplyButtonTap = { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.onSelect(strongSelf.data)
            strongSelf.dismiss(animated: true)
        }

        self.selectionView?.onClearButtonTap = { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.onSelect(strongSelf.data)
        }
    }
}
