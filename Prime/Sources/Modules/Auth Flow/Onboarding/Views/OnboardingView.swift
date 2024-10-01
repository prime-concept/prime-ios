import UIKit
import SnapKit

extension OnboardingView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray0
        var logoImageTintColor = Palette.shared.brandPrimary
        var closeButtonTintColor = Palette.shared.brandPrimary

        var nextButtonFont = Palette.shared.primeFont.with(size: 14)
        var nextButtonTitleColor = Palette.shared.gray5
        var nextButtonBorderColor = Palette.shared.brandSecondary
        var nextButtonBackgroundColor = Palette.shared.brown
        var nextButtonCornerRadius: CGFloat = 8
        var nextButtonBorderWidth: CGFloat = 0.5

        var currentPageIndicatorTintColor = Palette.shared.brandSecondary
        var pageIndicatorTintColor = Palette.shared.brandSecondary.withAlphaComponent(0.5)
    }
}

final class OnboardingView: UIView {
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColorThemed = self.appearance.closeButtonTintColor
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onClose?()
        }
        return button
    }()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColorThemed = self.appearance.logoImageTintColor
        return imageView
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(
            Localization.localize("auth.next").attributed()
                .foregroundColor(self.appearance.nextButtonTitleColor)
                .primeFont(ofSize: 14, lineHeight: 17)
                .string(),
            for: .normal
        )
        button.backgroundColorThemed = self.appearance.nextButtonBackgroundColor
        button.layer.cornerRadius = self.appearance.nextButtonCornerRadius
        button.layer.borderWidth = self.appearance.nextButtonBorderWidth
        button.layer.borderColorThemed = self.appearance.nextButtonBorderColor
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onNextButtonTap?()
        }
        return button
    }()

    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false
        pageControl.currentPageIndicatorTintColorThemed = self.appearance.currentPageIndicatorTintColor
        pageControl.pageIndicatorTintColorThemed = self.appearance.pageIndicatorTintColor
        pageControl.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        return pageControl
    }()

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = Palette.shared.clear
        return view
    }()

    var onClose: (() -> Void)?
    var onNextButtonTap: (() -> Void)?

    private let appearance: Appearance

	init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: OnboardingPageViewModel) {
        let isLastPage = viewModel.currentPageIndex == viewModel.numberOfPages - 1
        self.backgroundImageView.image = isLastPage ? UIImage(named: "onboarding-bg") : .none

        self.pageControl.numberOfPages = viewModel.numberOfPages
        self.pageControl.currentPage = viewModel.currentPageIndex
    }

    func addPageToContainer(view: UIView) {
        self.containerView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension OnboardingView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        [
            self.backgroundImageView,
            self.logoImageView,
            self.containerView,
            self.closeButton,
            self.nextButton,
            self.pageControl
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        self.backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.top.equalToSuperview().offset(44)
            make.leading.equalToSuperview().offset(15)
        }

        self.logoImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 73))
            make.top.equalToSuperview().offset(62)
            make.trailing.equalToSuperview().inset(25)
        }

        self.nextButton.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.leading.equalToSuperview().offset(57)
            make.trailing.greaterThanOrEqualToSuperview().inset(57)
        }

        self.pageControl.snp.makeConstraints { make in
            make.top.equalTo(self.nextButton.snp.bottom).offset(17)
            make.bottom.equalToSuperview().inset(59)
            make.centerX.equalToSuperview()
        }
    }
}
