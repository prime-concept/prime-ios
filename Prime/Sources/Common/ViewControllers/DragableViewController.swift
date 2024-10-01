import UIKit

extension DragableViewController {
	struct Appearance: Codable {
		var backgroundColor = Palette.shared.gray5
		var grabberHeaderHeight: CGFloat = 14
		var contentInsetTop: CGFloat = 14
	}
}

class DragableViewController: UIViewController {
	private(set) var contentViewController: UIViewController
	private let appearance: Appearance

	init(appearance: Appearance = Theme.shared.appearance(), contentViewController: UIViewController) {
		self.appearance = appearance
		self.contentViewController = contentViewController
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColorThemed = self.appearance.backgroundColor

		self.contentViewController.willMove(toParent: self)

		let grabberView = with(GrabberView()) { $0.make(.height, .equal, self.appearance.grabberHeaderHeight) }
		let contentView = self.contentViewController.view!

		self.view.addSubview(contentView)
		self.view.addSubview(grabberView)

		grabberView.make(.edges(except: .bottom), .equalToSuperview)
		grabberView.make(.height, .equal, self.appearance.grabberHeaderHeight)

		contentView.make(.edges(except: .top), .equalToSuperview)
		contentView.make(.top, .equalToSuperview, +self.appearance.contentInsetTop)

		self.contentViewController.didMove(toParent: self)
	}
}
