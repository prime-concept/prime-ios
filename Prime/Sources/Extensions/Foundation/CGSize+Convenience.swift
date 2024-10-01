import CoreGraphics

extension CGRect {
	var ratio: CGFloat {
		self.size.ratio
	}
}

extension CGSize {
	var ratio: CGFloat {
		self.width / self.height
	}
}
