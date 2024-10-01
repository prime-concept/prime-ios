
import UIKit
import SnapKit

extension CustomSegmentView {
    struct Appearance: Codable {
        var underlineViewColor = Palette.shared.gray3
        var bottomSelectionIndicatorColor = Palette.shared.gray0
        var bottomSelectionIndicatorViewHeight: CGFloat = 1
        var underlineViewHeight: CGFloat = 0.5
    }
}

final class CustomSegmentView: UIView {
    
    private let appearance: Appearance
    
    private lazy var segmentedControl: UISegmentedControl = {
        return makeSegmentedControlAppearance()
    }()
    
    private lazy var bottomSelectionIndicatorView: UIView = {
        let underlineView = UIView()
        underlineView.backgroundColor = appearance.bottomSelectionIndicatorColor.rawValue
        return underlineView
    }()
    
    private lazy var bottomUnderlineView: UIView = {
        let underlineView = UIView()
        underlineView.backgroundColor = appearance.underlineViewColor.rawValue
        return underlineView
    }()
    
    private lazy var leadingDistanceConstraint: Constraint? = nil
    
    //MARK: - Public Vriables
    var segmentTitles: [String] = [] {
        didSet {
            self.updateSegmentTitles()
        }
    }
    
    var selectedSegmentIndex: Int {
        get {
            return self.segmentedControl.selectedSegmentIndex
        }
        set {
            self.segmentedControl.selectedSegmentIndex = newValue
            self.changeSegmentedControlLinePosition()
        }
    }
    
    var selectedTitleColor: UIColor? {
        didSet {
            self.updateSelectionAppearance(state: .selected, color: selectedTitleColor)
        }
    }
    
    var deselectedTitleColor: UIColor? {
        didSet {
            self.updateSelectionAppearance(state: .normal, color: deselectedTitleColor)
        }
    }
    
    var titleFont: UIFont? {
        didSet {
            if let titleFont = titleFont {
                var titleAttributes: [NSAttributedString.Key: Any] = [:]
                titleAttributes[NSAttributedString.Key.font] = titleFont
                self.segmentedControl.setTitleTextAttributes(titleAttributes, for: .normal)
                self.segmentedControl.setTitleTextAttributes(titleAttributes, for: .selected)
            }
        }
    }
    
    var onSegmentChanged: ((Int) -> Void)?
    
    //MARK: - Internal Methods
    override init(frame: CGRect = .zero) {
        self.appearance = Theme.shared.appearance()
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        self.appearance = Theme.shared.appearance()
        super.init(coder: coder)
        self.setupView()
    }
    
    internal func setupView() {
        self.addSubviews()
        self.makeConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        /// For makeing  "bottomSelectionIndicatorView"  widht constrain need  pre-determined "segmentedControl" size.
        self.bottomSelectionIndicatorView.snp.makeConstraints { make in
            make.width.equalTo(self.segmentedControl.snp.width).dividedBy(self.segmentedControl.numberOfSegments > 0
                                                                          ? self.segmentedControl.numberOfSegments : 1)
        }
    }
    
    //MARK: - Private Methods
    private func makeSegmentedControlAppearance() ->UISegmentedControl {
        let segmentedControl = UISegmentedControl()
        
        segmentedControl.backgroundColor = .clear
        segmentedControl.tintColor = .clear
        
        segmentedControl.setBackgroundImage(
            UIImage(),
            for: .normal,
            barMetrics: .default
        )
        
        segmentedControl.setDividerImage(
            UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState: .normal,
            barMetrics: .default
        )
        
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: Palette.shared.gray5.rawValue
        ], for: .normal)
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        
        return segmentedControl
    }
    
    private func updateSegmentTitles() {
        self.segmentedControl.removeAllSegments()
        for (index, title) in segmentTitles.enumerated() {
            self.segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        selectedSegmentIndex = 0
    }
    
    private func updateSelectionAppearance(state: UIControl.State, color: UIColor?) {
        var titleAttributes: [NSAttributedString.Key: Any] = [:]
        if let titleColor = color {
            titleAttributes[NSAttributedString.Key.foregroundColor] = titleColor
        }
        self.segmentedControl.setTitleTextAttributes(titleAttributes, for: state)
    }
    
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        self.changeSegmentedControlLinePosition()
        self.onSegmentChanged?(sender.selectedSegmentIndex)
        self.updateSelectionAppearance(state: .selected, color: self.selectedTitleColor)
    }
    
    private func changeSegmentedControlLinePosition() {
        let segmentIndex = CGFloat(self.segmentedControl.selectedSegmentIndex)
        let segmentWidth = self.segmentedControl.frame.width / CGFloat(self.segmentedControl.numberOfSegments)
        let leadingDistance = segmentWidth * segmentIndex
        self.leadingDistanceConstraint?.update(offset: leadingDistance)
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.layoutIfNeeded()
        }
    }
}


extension CustomSegmentView: Designable {
    
    func addSubviews() {
        [
            self.segmentedControl,
            self.bottomSelectionIndicatorView,
            self.bottomUnderlineView
        ].forEach(self.addSubview)
    }
    
    func makeConstraints() {
        self.segmentedControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.bottomSelectionIndicatorView.snp.makeConstraints { make in
            make.bottom.equalTo(self.segmentedControl.snp.bottom)
            make.height.equalTo(appearance.bottomSelectionIndicatorViewHeight)
            leadingDistanceConstraint = make.left.equalTo(self.segmentedControl.snp.left).constraint
        }
        
        self.bottomUnderlineView.snp.makeConstraints { make in
            make.bottom.equalTo(self.segmentedControl.snp.bottom)
            make.height.equalTo(appearance.underlineViewHeight)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
    }
}
