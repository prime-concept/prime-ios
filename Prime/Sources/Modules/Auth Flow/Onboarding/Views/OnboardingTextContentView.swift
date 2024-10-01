import UIKit

extension OnboardingTextContentView {
    struct Appearance: Codable {
        var diagonalViewColor = Palette.shared.brown
        var headlineLabelTextColor = Palette.shared.brandPrimary
        var numberLabelTextColor = Palette.shared.brandPrimary
        var titleLabelTextColor = Palette.shared.gray5
    }
}

final class OnboardingTextContentView: UIView {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()

    private lazy var diagonalView: DiagonalView = {
        let view = DiagonalView()
        view.backgroundColorThemed = self.appearance.diagonalViewColor
        return view
    }()

    private lazy var headlineLabel = UILabel()
    private lazy var numberLabel = UILabel()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
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

    override func layoutSubviews() {
        super.layoutSubviews()
        self.drawDiagonalView()
    }

    func configure(with model: OnboardingTextContentViewModel) {
        self.headlineLabel.attributedTextThemed = model.headline.attributed()
            .foregroundColor(self.appearance.headlineLabelTextColor)
            .primeFont(ofSize: 10, weight: .bold, lineHeight: 12)
            .string()
        self.numberLabel.attributedTextThemed = model.number.attributed()
            .foregroundColor(self.appearance.numberLabelTextColor)
            .boldFancyFont(ofSize: 30, lineHeight: 52.5)
            .string()
        self.titleLabel.attributedTextThemed = model.title.attributed()
            .foregroundColor(self.appearance.titleLabelTextColor)
            .boldFancyFont(ofSize: 25, lineHeight: 28.75)
            .string()

        let isLastPage = model.currentPageIndex == model.numberOfPages - 1
        self.diagonalView.isHidden = isLastPage ? true : false

        let view: ReasonView

        switch model.currentPageIndex {
        case 0:
            view = FirstReasonView()
        case 2:
            view = SecondReasonView()
        case 4:
            view = ThirdReasonView()
        case 6:
            view = FourthReasonView()
        case 8:
            view = FifthReasonView()
        default:
            return
        }

        self.contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.configure(with: model)
    }

    // MARK: - Helpers

    private func drawDiagonalView() {
        let layerHeight = self.diagonalView.layer.frame.height
        let layerWidth = self.diagonalView.layer.frame.width
        self.diagonalView.points = [
            CGPoint(x: 0, y: layerHeight),
            CGPoint(x: layerWidth, y: layerHeight),
            CGPoint(x: layerWidth, y: layerHeight * 1 / 3),
            CGPoint(x: 0, y: layerHeight * 2 / 3)
        ]
    }
}

extension OnboardingTextContentView: Designable {
    func addSubviews() {
        [
            self.contentView
        ].forEach(self.scrollView.addSubview)
        [
            self.diagonalView,
            self.headlineLabel,
            self.numberLabel,
            self.titleLabel
        ].forEach(self.addSubview)
        self.addSubview(self.scrollView)
    }

    func makeConstraints() {
        self.diagonalView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.headlineLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(130)
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
            make.bottom.equalTo(self.titleLabel.snp.top).offset(-10)
        }

        self.numberLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(25)
            make.top.equalTo(self.headlineLabel.snp.bottom).offset(5)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
        }

        self.scrollView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalToSuperview().inset(170)
            make.trailing.equalToSuperview().inset(15)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(15)
        }

        self.contentView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalTo(self)
        }
    }
}
