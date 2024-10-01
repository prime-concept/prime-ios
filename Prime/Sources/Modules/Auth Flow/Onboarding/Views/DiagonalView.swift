import UIKit

class DiagonalView: UIView {
    var points: [CGPoint]? {
        didSet {
            self.draw(self.bounds)
        }
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
        // Get Height and Width
//        let layerHeight = self.layer.frame.height
//        let layerWidth = self.layer.frame.width
        // Create Path
        let bezierPath = UIBezierPath()
        //  Points
//        let pointA = CGPoint(x: 0, y: layerHeight)
//        let pointB = CGPoint(x: layerWidth, y: layerHeight)
//        let pointC = CGPoint(x: layerWidth, y: layerHeight * 1 / 3)
//        let pointD = CGPoint(x: 0, y: layerHeight * 2 / 3)
        guard let points = points,
              let pointA = points[safe: 0],
              let pointB = points[safe: 1],
              let pointC = points[safe: 2],
              let pointD = points[safe: 3] else {
            return
        }
//        let pointA = CGPoint(x: 0, y: layerHeight)
//        let pointB = CGPoint(x: layerWidth * 1 / 3, y: layerHeight)
//        let pointC = CGPoint(x: layerWidth * 3 / 4, y: 0)
//        let pointD = CGPoint(x: 0, y: 0)
        // Draw the path
        bezierPath.move(to: pointA)
        bezierPath.addLine(to: pointB)
        bezierPath.addLine(to: pointC)
        bezierPath.addLine(to: pointD)
        bezierPath.close()
        // Mask to Path
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        self.layer.mask = shapeLayer
    }
}
