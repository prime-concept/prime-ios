import UIKit
import Nuke

final class TripleBanner: UIView {
	private var firstImageView: UIImageView!
	private var secondImageView: UIImageView!
	private var thirdImageView: UIImageView!

	private var firstImagePad = UIView()
	private var secondImagePad = UIView()
	private var thirdImagePad = UIView()

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.clipsToBounds = true
		self.placeSubviews()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update(with viewModel: HomeBannerViewModel) {
		let imageViews = [self.firstImageView!,
						  self.secondImageView!,
						  self.thirdImageView!]

		imageViews.forEach{
			$0.image = nil
			$0.isHidden = true
		}

		for i in 0..<viewModel.banners.count {
			let banner = viewModel.banners[safe: i]
			let imageView = imageViews[safe: i]
			imageView?.image = banner?.image
			imageView?.addTapHandler {
                banner?.onTap(i)
			}
            imageView?.contentMode = .scaleAspectFill
			imageView?.isHidden = imageView?.image == nil
		}
	}

	private func placeSubviews() {
		let first = UIImageView()
		let second = UIImageView()
		let third = UIImageView()

		self.firstImageView = first
		self.secondImageView = second
		self.thirdImageView = third

		let imageViews = [first, second, third]
		imageViews.forEach { view in
			view.contentMode = .scaleAspectFit
			view.layer.cornerRadius = 10
			view.layer.masksToBounds = true
		}

		let secondTopSpacer = UIView()
		let secondTrailingSpacer = UIView()
		let thirdTopSpacer = UIView()

		self.addSubviews(secondTopSpacer, secondTrailingSpacer, thirdTopSpacer)
		self.addSubviews(first, second, third)

		first.make([.top, .leading], .equalToSuperview)
		first.make(.height, .equal, to: 125 ~/ 138, of: self)
		first.make(ratio: 249 ~/ 125)

		second.make(.height, .equal, to: 77 ~/ 138, of: self)
		second.make(ratio: 141 ~/ 77)
		second.make(.bottom, .equalToSuperview)
		second.place(under: secondTopSpacer)
		secondTopSpacer.make(.edges(except: .bottom), .equalToSuperview)
		secondTopSpacer.make(.height, .equal, to: 61 ~/ 138, of: self)
		secondTrailingSpacer.place(behind: second)
		secondTrailingSpacer.make(.edges(except: .leading), .equalToSuperview)
		secondTrailingSpacer.make(.width, .equal, to: 55 ~/ 345, of: self)

		third.make(.trailing, .equalToSuperview)
		third.make(.height, .equal, to: 77 ~/ 138, of: self)
		third.make(ratio: 1)

		third.place(under: thirdTopSpacer)
		thirdTopSpacer.make(.edges(except: .bottom), .equalToSuperview)
		thirdTopSpacer.make(.height, .equal, to: 23 ~/ 138, of: self)

		let pads = [self.firstImagePad, self.secondImagePad, self.thirdImagePad]
		for i in 0..<pads.count {
			let imageView = imageViews[i]
			let pad = pads[i]

			self.insertSubview(pad, belowSubview: imageView)
			pad.make(.edges, .equal, to: imageView)

			pad.backgroundColorThemed = Palette.shared.gray5
			pad.layer.cornerRadius = imageView.layer.cornerRadius
		}
	}
}
