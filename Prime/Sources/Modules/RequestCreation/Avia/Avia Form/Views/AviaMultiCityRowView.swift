import UIKit

extension AviaMultiCityRowView {
    struct Appearance: Codable {
        var separatorColor = Palette.shared.gray4
    }
}

final class AviaMultiCityRowView: UIView {
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.backgroundColorThemed = Palette.shared.clear
        return stackView
    }()

    private lazy var rowDeletionButton = UIImageView(image: .init(named: "avia_delete"))
    private lazy var separatorView = OnePixelHeightView()

    private let appearance: Appearance

    var onDepartureFieldTap: (() -> Void)?
    var onArrivalFieldTap: (() -> Void)?
    var onDateTap: (() -> Void)?

    var onDelete: (() -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
        self.setup()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        let departureCellView = AviaMultiCityCellView()
        departureCellView.addTapHandler { [weak self] in
            self?.onDepartureFieldTap?()
        }

        let arrivalCellView = AviaMultiCityCellView()
        arrivalCellView.addTapHandler { [weak self] in
            self?.onArrivalFieldTap?()
        }
        self.placeSeparator(on: arrivalCellView)

        let dateCellView = AviaMultiCityCellView()
        dateCellView.addTapHandler { [weak self] in
            self?.onDateTap?()
        }
        self.placeSeparator(on: dateCellView)

        [
            departureCellView,
            arrivalCellView,
            dateCellView
        ].forEach(self.stackView.addArrangedSubview)
    }

    func setup(with viewModel: MultiCityViewModel.Row) {
        if viewModel.shouldShowDeletion {
            self.addSubview(self.rowDeletionButton)
            self.rowDeletionButton.snp.makeConstraints { make in
                make.height.width.equalTo(24)
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-13)
            }
            self.rowDeletionButton.addTapHandler { [weak self] in
                self?.onDelete?()
            }
        }
        self.stackView.arrangedSubviews.enumerated().forEach { iterator in
            guard let view = iterator.element as? AviaMultiCityCellView else {
                return
            }
            switch iterator.offset {
            case 0:
                view.setup(with: viewModel.origin)
            case 1:
                view.setup(with: viewModel.destination)
            case 2:
                view.setup(with: viewModel.date)
            default:
                return
            }
        }
    }

    private func placeSeparator(on view: UIView) {
        let separator = UIView()
        separator.backgroundColorThemed = self.appearance.separatorColor
        view.addSubview(separator)

        separator.snp.remakeConstraints { make in
            make.width.equalTo(1 / UIScreen.main.scale)
            make.height.equalTo(30)
            make.centerY.leading.equalToSuperview()
        }
    }

    private func makeCellView() -> AviaMultiCityCellView {
        let view = AviaMultiCityCellView()
        return view
    }
}

extension AviaMultiCityRowView: Designable {
    func setupView() {
        self.separatorView.backgroundColorThemed = self.appearance.separatorColor
    }

    func addSubviews() {
        self.addSubview(self.stackView)
        self.addSubview(self.separatorView)
    }

    func makeConstraints() {
        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}

extension AviaMultiCityCellView {
    struct Appearance: Codable {
        var titleTextColor = Palette.shared.gray0
        var subtitleTextColor = Palette.shared.gray1
        var placeholderTextColor = Palette.shared.gray1
    }
}

final class AviaMultiCityCellView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var subTitleLabel = UILabel()
    private lazy var placeholderLabel = UILabel()

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }

    private let appearance: Appearance

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    func setup(with viewModel: MultiCityViewModel.Cell) {
        guard let title = viewModel.title , let subtitle = viewModel.subtitle else {
            self.placeholderLabel.isHidden = false
            self.placeholderLabel.attributedTextThemed = viewModel.placeholder.attributed()
                .primeFont(ofSize: 13, lineHeight: 16)
                .foregroundColor(self.appearance.placeholderTextColor)
                .string()
            return
        }
        self.placeholderLabel.isHidden = true
        self.titleLabel.attributedTextThemed = title.attributed()
            .primeFont(ofSize: 13, lineHeight: 16)
            .foregroundColor(self.appearance.titleTextColor)
            .string()
        self.subTitleLabel.attributedTextThemed = subtitle.attributed()
            .primeFont(ofSize: 13, lineHeight: 16)
            .foregroundColor(self.appearance.subtitleTextColor)
            .string()
    }
}

extension AviaMultiCityCellView: Designable {
    func setupView() {}

    func addSubviews() {
        [
            self.titleLabel,
            self.subTitleLabel,
            self.placeholderLabel
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.equalToSuperview().inset(15)
            make.trailing.equalToSuperview().inset(5)
        }

        self.subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalTo(self.titleLabel)
        }

        self.placeholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(self.titleLabel)
        }
    }
}

struct MultiCityViewModel {
    struct Row {
        var origin: Cell
        var destination: Cell
        var date: Cell
        var shouldShowDeletion = false
    }

    struct Cell {
        var title: String?
        var subtitle: String?
        let placeholder: String
    }

    enum Mode {
        case edit, update(Int)
    }

    var rows: [Row]
    var mode: Mode
}
