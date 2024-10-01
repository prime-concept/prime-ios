import SnapKit
import UIKit

protocol RequestCreationViewProtocol: ModalRouterSourceProtocol {
    var requestInputView: UIView { get }
    func displayChild(viewController: UIViewController)
    func update(with: RequestCreationViewModel)
    func selectTask(at index: Int)
    func showLoading()
    func hideLoading()
    func show(error: String)
}

struct RequestCreationViewModel {
    init(
        header: TaskAccessoryHeaderViewModel? = nil,
        categories: RequestCreationCategoriesViewModel? = nil,
		tasks: [ActiveTaskViewModel],
		nearestTaskIndex: Int? = nil
    ) {
        self.header = header
        self.categories = categories
		self.tasks = tasks
		self.nearestTaskIndex = nearestTaskIndex
    }

    let header: TaskAccessoryHeaderViewModel?
    let categories: RequestCreationCategoriesViewModel?

	let tasks: [ActiveTaskViewModel]
	let nearestTaskIndex: Int?
}

final class RequestCreationViewController: UIViewController {
	// Баг или просто странное поведение в поде IQKeyboardManager.
	// Вычислялся неверный ориджин для вьюхи контроллера, и контроллер
	// постоянно уезжал вверх.
	// (см. PRIMEIOS-283 Некорректно работает окно создания запроса)
	private class TopZeroView: UIView {
		override var frame: CGRect {
			didSet {
				if self.frame.origin.y != 0 {
					self.frame.origin.y = 0
				}
			}
		}
	}

	private var tasks: [ActiveTaskViewModel] = []
	private var nearestTaskIndex: Int? = nil
	private var didScrollToNearestTask: Bool = false

    private lazy var tasksCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 177, height: 62)
        layout.minimumLineSpacing = 3
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = .init(top: 0, left: 10, bottom: 0, right: 10)
		collectionView.backgroundColorThemed = Palette.shared.clear
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(cellClass: TaskAccessoryCollectionViewCell.self)
        collectionView.snp.makeConstraints { $0.height.equalTo(64) }
        return collectionView
    }()

    // MARK: - Public methods
    private lazy var contentStackView: UIStackView = {
        let containerStackView = UIStackView()
		containerStackView.backgroundColorThemed = Palette.shared.clear
        containerStackView.axis = .vertical
        containerStackView.spacing = 0
        containerStackView.addArrangedSubview(self.taskAccessoryHeaderView)
        containerStackView.addArrangedSubview(self.tasksCollectionView)
        containerStackView.addArrangedSubview(self.categoriesView)
        return containerStackView
    }()

    private lazy var taskAccessoryHeaderView = TaskAccessoryHeaderView()
    private lazy var categoriesView = RequestCreationCategoriesSelectionView()

    private let presenter: RequestCreationPresenterProtocol
    private var currentChild: UIViewController?

    init(presenter: RequestCreationPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func loadView() {
		self.view = TopZeroView()
        self.view.backgroundColorThemed = Palette.shared.gray5
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter.didLoad()
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.presenter.didAppear()

		delay(0.1) {
			self.scrollToNearestTaskIfNeeded()
		}
	}
}

extension RequestCreationViewController: RequestCreationViewProtocol {
    func showLoading() {
		self.view.showLoadingIndicator()
    }

    func hideLoading() {
        HUD.find(on: self.view)?.remove(animated: true)
    }

	var requestInputView: UIView {
		let inputView = SystemHeightIgnoringInputView(
			frame: .zero,
			inputViewStyle: .keyboard
		)
		inputView.addSubview(contentStackView)
		contentStackView.snp.makeConstraints {
			$0.edges.equalToSuperview()
		}
		return inputView
	}

    func displayChild(viewController: UIViewController) {
        self.currentChild?.view.removeFromSuperview()
        self.currentChild?.removeFromParent()
        self.addChild(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.currentChild = viewController
        viewController.didMove(toParent: self)
    }

    func update(with viewModel: RequestCreationViewModel) {
		self.tasks = viewModel.tasks
		self.nearestTaskIndex = viewModel.nearestTaskIndex

        viewModel.header.some {
            self.taskAccessoryHeaderView.update(with: $0)
            let taskCollectionHidden = ($0.selected != .existing) || self.tasks.isEmpty
            self.tasksCollectionView.isHidden = taskCollectionHidden
			self.categoriesView.isHidden = $0.selected != .new
        }
        viewModel.categories.some {
            self.categoriesView.update(with: $0)
        }

		self.tasksCollectionView.reloadData()

		delay(0.3) {
			self.scrollToNearestTask()
		}
    }

	private func scrollToNearestTask() {
		guard let index = self.nearestTaskIndex else {
			self.view.setNeedsLayout()
			self.view.layoutIfNeeded()

			var offsetX = self.tasksCollectionView.contentSize.width - self.tasksCollectionView.bounds.width
			offsetX = max(-self.tasksCollectionView.contentInset.left, offsetX)

			self.tasksCollectionView.contentOffset.x = offsetX

			return
		}

		let indexPath = IndexPath(row: index, section: 0)
		self.tasksCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
	}

	private func scrollToNearestTaskIfNeeded() {
		if self.didScrollToNearestTask {
			return
		}

		self.scrollToNearestTask()
		self.didScrollToNearestTask = true
	}

    func selectTask(at index: Int) {
        self.tasksCollectionView.selectItem(
            at: IndexPath(row: index, section: 0),
            animated: true,
            scrollPosition: [.centeredHorizontally, .centeredVertically]
        )
    }

    func show(error: String) {
        let alert = UIAlertController(title: nil, message: error, preferredStyle: .alert)
        alert.addAction(.init(title: "common.ok".localized.uppercased(), style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

extension RequestCreationViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
		self.tasks.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell: TaskAccessoryCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
		let model = self.tasks[indexPath.item]
        cell.setup(with: model)
        return cell
    }
}

extension RequestCreationViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.selectItem(
            at: indexPath,
            animated: true,
            scrollPosition: [.centeredHorizontally, .centeredVertically]
        )
        self.presenter.didSelectTask(at: indexPath.item)
    }
}

extension NSLayoutConstraint {
    var isPureHeightConstraint: Bool {
        self.firstAttribute == .height && self.secondAttribute == .notAnAttribute
    }
}
extension Bool {
	static func |= (_ lhs: inout Bool, _ rhs: Bool) {
		lhs = lhs || rhs
	}
}

private final class SystemHeightIgnoringInputView: UIInputView {
	override var intrinsicContentSize: CGSize {
		self.suppressSystemHeight()
		let size = CGSize(
			width: UIView.noIntrinsicMetric,
			height: self.subviews.reduce(0) {
				$0 + $1.intrinsicContentSize.height
			}
		)
		return size
	}

	private func suppressSystemHeight() {
		self.constraints
			.filter { $0.isPureHeightConstraint }
			.forEach { $0.isActive = false }
	}
}
