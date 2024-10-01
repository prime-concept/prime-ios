import UIKit
import MapKit
import ChatSDK

class PartialMapViewController: UIViewController, MKMapViewDelegate {
    
	var location: CLLocationCoordinate2D? {
		didSet {
			self.updateShareButton()
		}
	}

    private lazy var contentStackView = UIStackView.vertical()
    
    private lazy var mapView: UIView = {
        MapContainerView(frame: view.bounds, location: location)
    }()
    
    private lazy var mainVStack = with(UIStackView(.vertical)) { stack in
        stack.addArrangedSubviews(
            self.headerViewContainer,
            self.mapView
        )
    }

    private lazy var headerViewContainer = with(UIStackView(.vertical)) { stack in
        stack.addArrangedSubview(self.headerView)

        stack.setContentHuggingPriority(.defaultHigh, for: .vertical)
        stack.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    private lazy var headerView = with(MapCustomNavigationBar(rightButtonImageName: "share_icon",
                                                           title: "task.detail.location.name".localized)) { view in
        view.make(.height, .equal, 60)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.mainVStack)
        self.mainVStack.make(.edges, .equalToSuperview)
        self.updateShareButton()
    }
    
    private func updateShareButton() {
		self.headerView.rightButton.isHidden = true

		guard let lat = self.location?.latitude,
			  let long = self.location?.longitude else {
			return
		}

		self.headerView.rightButton.isHidden = false

		self.headerView.onRightButtonTap = {
			Sharing.manager.share(latitude: lat, longitude: long)
		}
    }
}

final class MapCustomNavigationBar: LeftTitleCustomNavigationBar {

    override func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.fontThemed = Palette.shared.primeFont.with(size: 16, weight: .medium)
        label.text = self.title
        return label
    }
    
    override func makeConstraints() {
        self.grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(3)
        }

        self.rightButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(18)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(self.grabberView.snp.bottom).offset(25)
        }

        self.rightButton.toFront()
    }
}
