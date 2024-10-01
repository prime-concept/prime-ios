import UIKit

extension RequestBlockItemEmptyCreationView {
    struct Appearance {
        let containerBackgroundColor = Palette.secondGold.withAlphaComponent(0.8)
        let containerCornerRadius: CGFloat = 5

        let titleFont = UIFont.primeFont(ofSize: 14, weight: .medium)
        let titleTextColor: UIColor = .white

        let addTintColor: UIColor = .white

        let overlayBackgroundColor: UIColor = .clear

        let logoCornerRadius: CGFloat = 22
    }
}

final class RequestBlockItemEmptyCreationView: UIView {
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = self.appearance.containerBackgroundColor
        view.layer.cornerRadius = self.appearance.containerCornerRadius
        return view
    }()

    private lazy var logoView = TaskInfoTypeView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = self.appearance.titleFont
        label.textColor = self.appearance.titleTextColor
        // swiftlint:disable:next prime_font
        label.text = "createTask".localized
        return label
    }()

    private lazy var addIconImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(named: "plus_icon")?.withRenderingMode(.alwaysTemplate)
        )
        imageView.tintColor = self.appearance.addTintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var overlayButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = self.appearance.overlayBackgroundColor
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            guard let strongSelf = self, let viewModel = strongSelf.viewModel else {
                return
            }

            viewModel.addTaskAction?(viewModel.type)
        }
        return button
    }()

    private let appearance: Appearance

    private var viewModel: RequestBlockItemCreationViewModel?

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
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

    func setup(with viewModel: RequestBlockItemCreationViewModel) {
        self.viewModel = viewModel
        self.logoView.set(image: viewModel.type.image)
    }
}

extension RequestBlockItemEmptyCreationView: Designable {
    func setupView() {
        self.logoView.layer.cornerRadius = 22
        self.logoView.dropShadow(radius: 2)
    }

    func addSubviews() {
        [self.containerView, self.logoView].forEach(self.addSubview)
        [
            self.titleLabel,
            self.addIconImageView,
            self.overlayButton
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.leading.equalToSuperview().offset(30)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-9)
        }

        self.logoView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 44, height: 44))
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(3)
            make.bottom.equalToSuperview().offset(-7)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalTo(self)
        }

        self.addIconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14, height: 14))
            make.trailing.equalToSuperview().offset(-14)
        }

        self.overlayButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
