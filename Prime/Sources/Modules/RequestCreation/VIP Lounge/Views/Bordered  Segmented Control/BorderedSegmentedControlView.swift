import UIKit
import SnapKit

class BorderedSegmentedControlView: UIView {
    
    var segmentSelectionCallback: ((Int) -> Void)?
    private var themedColor: ThemedColor!
    
    let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    private lazy var borderedView = UIView()
    
    private func configureView() {
        addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().inset(15)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().inset(10)
        }
    }
    
    func setup(with titles: [String], color: ThemedColor) {
        
        self.themedColor = color.addDecorator(with: { [weak self] color in
            self?.segmentedControl.layer.borderColor = color.cgColor
            self?.segmentedControl.selectedSegmentTintColor = color
            return color
        })
        
        for title in titles {
            segmentedControl.insertSegment(withTitle: title, at: titles.count, animated: false)
        }
        
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.setTitleTextAttributes([.foregroundColorThemed: Palette.shared.gray0,
                                                      .fontThemed: Palette.shared.primeFont.with(size: 13)], for: .normal)
        
        self.segmentedControl.setTitleTextAttributes([.foregroundColor: Palette.shared.gray5,
                                                      .fontThemed: Palette.shared.primeFont.with(size: 13)], for: .selected)
        
        // Add border with color on segment controll
        self.segmentedControl.layer.borderColorThemed = color
        self.segmentedControl.layer.borderWidth = 0.2
        self.segmentedControl.layer.cornerRadius = 5.0
        
        self.segmentedControl.addTarget(self, action: #selector(self.segmentedControlValueChanged(_:)), for: .valueChanged)
    }
    
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        segmentSelectionCallback?(selectedIndex)
    }
}

