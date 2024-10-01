import UIKit
import SnapKit
import CoreHaptics
import IQKeyboardManagerSwift

extension PinCodeView {
    struct Appearance {
        let titleColor = UIColor.white

        let logoutButtonTextColor = Palette.mainRed
        let biometryButtonTextColor = Palette.darkGold

        let backgroundColor = Palette.nobleBrown
    }
}

final class PinCodeView: UIView {
    private lazy var logoutButton: UIView = {
        let label = UILabel()
        label.attributedText = Localization.localize("auth.logout").attributed()
            .foregroundColor(self.appearance.logoutButtonTextColor)
            .primeFont(ofSize: 16, lineHeight: 20)
            .string()

        let view = label.withExtendedTouchArea(insets: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
        view.addTapHandler { [weak self] in
            self?.onLogout?()
        }

        view.isHidden = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()

    private lazy var pinView: PinView = {
        let view = PinView()
        view.onPinEntered = { [weak self] pin in
            self?.onPinEntered?(pin)
        }
        return view
    }()

    private lazy var repeatPinView: PinView = {
        let view = PinView()
        view.isHidden = true
        view.onPinEntered = { [weak self] pin in
            self?.onPinEntered?(pin)
        }
        return view
    }()

    private lazy var biometryButton: UILabel = {
        let button = UILabel()
        button.isHidden = true
        return button
    }()

    private lazy var contentView = UIView()

    private var stackViewCenterXConstraint: Constraint?

    private let appearance: Appearance

    // MARK: - Button action closures

    var onFaceIDSelected: (() -> Void)?
    var onFingerprintSelected: (() -> Void)?
    var onPinEntered: ((String) -> Void)?
    var onLogout: (() -> Void)?

    init(appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func update(viewModel: PinCodeViewModel) {
        self.titleLabel.attributedText = viewModel.title.attributed()
            .foregroundColor(self.appearance.titleColor)
            .primeFont(ofSize: 20, weight: .bold, lineHeight: 24)
            .lineBreakMode(.byTruncatingTail)
            .alignment(.center)
            .string()

        if case .enter = viewModel.mode {
            self.logoutButton.isHidden = false

            self.biometryButton.isHidden = false
            self.biometryButton.attributedText = viewModel.biometry?.buttonTitle.attributed()
                .foregroundColor(self.appearance.biometryButtonTextColor)
                .primeFont(ofSize: 16, lineHeight: 20)
                .alignment(.center)
                .string()

            switch viewModel.biometry {
            case .faceID:
                self.biometryButton.addTapHandler { [weak self] in
                    self?.onFaceIDSelected?()
                }

            case .touchID:
                self.biometryButton.addTapHandler { [weak self] in
                    self?.onFingerprintSelected?()
                }

            case .none:
                self.biometryButton.isHidden = true
            }
        }

        switch viewModel.action {
        case .error:
            self.pinView.hasError = true
            self.repeatPinView.hasError = true
            self.contentView.shake {
                self.pinView.clear()
                self.repeatPinView.clear()
                self.repeatPinView.isHidden = true
                self.pinView.becomeFirstResponder()
            }

        case .next:
            self.animateFadeInOut()
            self.repeatPinView.isHidden = false
            self.repeatPinView.becomeFirstResponder()

        case .normal:
            self.pinView.becomeFirstResponder()
            self.pinView.clear()
            self.repeatPinView.clear()
        }
    }

    func setBiometryButtonConstraints(with offset: CGFloat) {
        self.biometryButton.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview().offset(35)
            make.trailing.equalToSuperview().offset(-35)
            make.bottom.equalToSuperview().offset(-offset - 21)
        }
    }

    // MARK: - Private

    private func animateFadeInOut() {
        self.stackViewCenterXConstraint?.update(offset: -1000)

        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.stackViewCenterXConstraint?.update(offset: 1000)
                self.layoutIfNeeded()

                UIView.animate(withDuration: 0.25) {
                    self.stackViewCenterXConstraint?.update(offset: 0)
                    self.layoutIfNeeded()
                }
            }
        )
    }
}

extension PinCodeView: Designable {
    func setupView() {
        self.backgroundColor = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.addSubview(self.contentView)

        [
            self.logoutButton,
            self.titleLabel,
            self.pinView,
            self.repeatPinView,
            self.biometryButton
        ].forEach(self.contentView.addSubview)
    }

    func makeConstraints() {
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.logoutButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().offset(-15)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.right.left.equalToSuperview().inset(30)
            make.top.equalToSuperview().offset(139)
            self.stackViewCenterXConstraint = make.centerX.equalToSuperview().constraint
        }

        self.pinView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
        }

        self.repeatPinView.snp.makeConstraints { make in
            make.top.equalTo(self.pinView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
    }
}

private extension UIView {
    func shake(completion: (() -> Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        let animationKeyPath = "transform.translation.x"
        let shakeAnimation = "shake"
        let duration = 0.6
        let animation = CAKeyframeAnimation(keyPath: animationKeyPath)
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = duration
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        self.layer.add(animation, forKey: shakeAnimation)

        CATransaction.commit()
    }
}
