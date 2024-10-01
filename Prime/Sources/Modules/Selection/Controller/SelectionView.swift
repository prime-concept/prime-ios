import UIKit

extension SelectionView {
    struct Appearance: Codable {
        var collectionBackground = Palette.shared.gray5
        var collectionItemSize = CGSize(width: UIScreen.main.bounds.width, height: 55)

        var clearBackgroundColor = Palette.shared.gray5
        var clearFont = Palette.shared.primeFont.with(size: 16)
        var clearTextColor = Palette.shared.gray0
        var clearBorderWidth: CGFloat = 0.5
        var clearBorderColor = Palette.shared.gray3

        var applyBackgroundColor = Palette.shared.brandPrimary
        var applyFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
        var applyTextColor = Palette.shared.gray5

        var buttonCornerRadius: CGFloat = 8
    }
}

final class SelectionView: UIView {
    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.appearance.collectionItemSize
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackground

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(cellClass: SelectionCollectionViewCell.self)
        return collectionView
    }()

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.clearButton, self.applyButton])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        return stackView
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)

        // swiftlint:disable:next prime_font
        button.setTitle(Localization.localize("selection.clear"), for: .normal)
        button.titleLabel?.fontThemed = self.appearance.clearFont
        button.setTitleColor(self.appearance.clearTextColor, for: .normal)

        button.backgroundColorThemed = self.appearance.clearBackgroundColor

        button.layer.borderWidth = self.appearance.clearBorderWidth
        button.layer.borderColorThemed = self.appearance.clearBorderColor

        button.layer.cornerRadius = self.appearance.buttonCornerRadius

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.clear()
        }

        return button
    }()

    private lazy var applyButton: UIButton = {
        let button = UIButton(type: .system)

        // swiftlint:disable:next prime_font
        button.setTitle(Localization.localize("selection.apply"), for: .normal)
        button.titleLabel?.fontThemed = self.appearance.applyFont
        button.setTitleColor(self.appearance.applyTextColor, for: .normal)

        button.backgroundColorThemed = self.appearance.applyBackgroundColor

        button.layer.cornerRadius = self.appearance.buttonCornerRadius

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.apply()
        }

        return button
    }()

    private let appearance: Appearance

    private var data: TaskCreationFieldViewModel?
    private var selectedOptions: [String] = []

    var onApplyButtonTap: (() -> Void)?
    var onClearButtonTap: (() -> Void)?

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
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

    private func clear() {
        selectedOptions = []
        self.collectionView.reloadData()

        self.onClearButtonTap?()
    }

    private func apply() {
        guard let data = data else {
            return
        }
        data.input.dictionaryOptions = selectedOptions
        self.onApplyButtonTap?()
    }

    func setup(with data: TaskCreationFieldViewModel, allowMultipleSelection: Bool) {
        self.data = data
        self.selectedOptions = data.input.dictionaryOptions
        self.collectionView.allowsMultipleSelection = allowMultipleSelection
        self.collectionView.reloadData()
    }
}

extension SelectionView: Designable {
    func setupView() {
    }

    func addSubviews() {
        [self.collectionView, self.buttonsStackView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.collectionView.snp.makeConstraints { make in
			make.leading.trailing.equalToSuperview()
			make.top.equalToSuperview().inset(30)
        }

        self.buttonsStackView.snp.makeConstraints { make in
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-15)
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.equalTo(self.collectionView.snp.bottom).offset(26)
        }

        self.clearButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.applyButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }
}

extension SelectionView: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let data = data else {
            return 0
        }
        return data.form.options.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let data = data else {
            return UICollectionViewCell()
        }
        let cell: SelectionCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

        if let item = data.form.options[safe: indexPath.row] {
            let isSelected = selectedOptions.contains(item.value)
            cell.setup(value: item.name, isSelected: isSelected)
        }

        return cell
    }
}

extension SelectionView: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let data = data else {
            return
        }
        if collectionView.allowsMultipleSelection == false {
            selectedOptions = []
        }
        selectedOptions += [data.form.options[indexPath.item].value]
        collectionView.reloadData()
    }
}
