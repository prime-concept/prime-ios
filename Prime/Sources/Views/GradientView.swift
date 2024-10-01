import UIKit

class GradientView: UIView {
    override public class var layerClass: Swift.AnyClass {
        CAGradientLayer.self
    }

    var colors: [ThemedColor] = [] {
        didSet {
            self.setLayerColors(colors: colors)
        }
    }

    var isHorizontal: Bool = false {
        didSet {
            self.setLayerColors(colors: colors)
        }
    }

	var points: (start: CGPoint, end: CGPoint) {
		didSet {
			self.setLayerColors(colors: colors)
		}
	}

    private func setLayerColors(colors: [ThemedColor]) {
        guard let gradientLayer = self.layer as? CAGradientLayer else {
            return
        }
		
        gradientLayer.colorsThemed = colors
		
        if isHorizontal {
			gradientLayer.startPoint = self.points.start
            gradientLayer.endPoint = self.points.end
        } else {
			gradientLayer.startPoint = self.points.start.yx
			gradientLayer.endPoint = self.points.end.yx
        }
    }

    init() {
		self.points = (start: CGPoint(x: 0.0, y: 0.5), end: CGPoint(x: 1.0, y: 0.5))

        super.init(frame: .zero)
        self.backgroundColorThemed = Palette.shared.clear
        self.setLayerColors(colors: self.colors)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CGPoint {
	var yx: CGPoint {
		CGPoint(x: y, y: x)
	}
}
