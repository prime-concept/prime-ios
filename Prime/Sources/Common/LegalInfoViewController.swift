import UIKit

final class LegalInfoViewController: UIViewController {
	private let pdfContent: UIImage?
	private var shouldSetupView = true

	init(pdfContent: UIImage?) {
		self.pdfContent = pdfContent
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColorThemed = Palette.shared.gray5
		self.addGrabberView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if self.shouldSetupView {
			self.showLoadingIndicator()
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.setupViewIfNeeded()
	}

	private func setupViewIfNeeded() {
		guard self.shouldSetupView else {
			return
		}

		self.shouldSetupView = false
		
		let imageView = UIImageView()
		imageView.contentMode = .scaleAspectFit
		imageView.image = self.pdfContent

		let scrollView = UIScrollView()
		self.view.addSubview(scrollView)

		scrollView.make(.edges, .equal, to: self.view.safeAreaLayoutGuide, [24, 0, 0, 0])
		scrollView.make(.width, .equal, to: self.view.safeAreaLayoutGuide)

		let ratio = 1 / (imageView.image?.size.ratio ?? 1)

		scrollView.addSubview(imageView)
		imageView.make(.width, .equal, to: self.view.safeAreaLayoutGuide)
		imageView.make(.edges, .equalToSuperview)
		imageView.make(.height, .equal, to: ratio, .width, of: imageView)

		self.hideLoadingIndicator()
	}

	private func addGrabberView() {
		let grabberView = UIView()
		grabberView.layer.cornerRadius = 2
		grabberView.backgroundColorThemed = Palette.shared.gray3
		self.view.addSubview(grabberView)
		grabberView.snp.makeConstraints { make in
			make.centerX.equalToSuperview()
			make.size.equalTo(CGSize(width: 36, height: 4))
			make.top.equalToSuperview().offset(10)
		}
	}
}
