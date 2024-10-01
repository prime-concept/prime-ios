import UIKit
import SnapKit

extension OnboardingPageView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.clear
    }
}

final class OnboardingPageView: UIView {
    private lazy var textContentView: OnboardingTextContentView = {
        let view = OnboardingTextContentView()
        view.isHidden = true
        return view
    }()

    private lazy var starContentView: OnboardingStarContentView = {
        let view = OnboardingStarContentView()
        view.isHidden = true
        return view
    }()

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
        if let textContent = viewModel as? OnboardingTextContentViewModel {
            textContentView.isHidden = false
            textContentView.configure(with: textContent)
        } else if let starContent = viewModel as? OnboardingStarContentViewModel {
            starContentView.isHidden = false
            starContentView.configure(with: starContent)
        }
    }
}

extension OnboardingPageView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        [
            self.textContentView,
            self.starContentView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.textContentView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        self.starContentView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}
