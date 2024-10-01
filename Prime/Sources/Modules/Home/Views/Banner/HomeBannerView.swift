import UIKit

final class HomeBannerCollectionViewCell: UICollectionViewCell, Reusable {
	override init(frame: CGRect) {
		super.init(frame: frame)

		self.addSubviews()
		self.makeConstraints()
	}

	private var topConstraint: NSLayoutConstraint?
	private var bottomConstraint: NSLayoutConstraint?

	private var topInset: CGFloat {
		get { self.topConstraint?.constant ?? 0 }
		set { self.topConstraint?.constant = newValue }
	}

	private var bottomInset: CGFloat {
		get { -(self.bottomConstraint?.constant ?? 0) }
		set { self.bottomConstraint?.constant = -newValue }
	}

	private(set) var imageView = UIImageView { imageView in
		imageView.contentMode = .scaleAspectFill
		imageView.layer.cornerRadius = 8
		imageView.clipsToBounds = true
		imageView.backgroundColorThemed = Palette.shared.gray5
	}

	private(set) var tripleBanner = TripleBanner()

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup(
		with viewModel: HomeBannerViewModel,
		extendsBottomInset: Bool = false,
		diminishesTopInset: Bool = false
	) {
		self.tripleBanner.isHidden = viewModel.banners.count == 1
		self.imageView.isHidden = !self.tripleBanner.isHidden

		defer {
			self.topInset = CGFloat(diminishesTopInset ? 0 : 9)
			self.bottomInset = CGFloat(extendsBottomInset ? 11 : 6)
		}

		if  viewModel.banners.isEmpty {
			return
		}

		if viewModel.banners.count > 1 {
			self.tripleBanner.update(with: viewModel)
			return
		}

		let banner = viewModel.banners[0]
		self.imageView.image = banner.image
		self.imageView.addTapHandler {
			banner.onTap(nil)
		}
	}
}

extension HomeBannerCollectionViewCell: Designable {
	func addSubviews() {}

	func makeConstraints() {
		self.contentView.make(.edges, .equalToSuperview)

		let container = UIStackView.vertical(
			self.imageView,
			self.tripleBanner
		)

		self.addSubview(container)
		self.imageView.make(ratio: 345 ~/ 130)
		self.tripleBanner.make(ratio: 345 ~/ 138)

		container.make(.hEdges, .equalToSuperview, [15, -15])
		
		let vConstraints =  container.make(.vEdges, .equalToSuperview, [9, -6], priorities: [.init(999)])
		self.topConstraint = vConstraints.first
		self.bottomConstraint = vConstraints.last
	}
}
