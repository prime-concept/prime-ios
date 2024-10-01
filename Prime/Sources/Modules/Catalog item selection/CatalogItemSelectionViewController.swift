import PhoneNumberKit
import UIKit

protocol CatalogItemSelectionControllerProtocol: AnyObject {
    func reload()
	func showLoading()
	func hideLoading()
}

extension CatalogItemSelectionViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var collectionBackgroundColor = Palette.shared.clear
		var collectionItemSize = CGSize(
			width: UIScreen.main.bounds.width,
			height: 55
		 )
        var searchTextFieldCornerRadius: CGFloat = 10
		var searchHintFont = Palette.shared.primeFont.with(size: 12)
		var searchHintColor = Palette.shared.gray1
        var grabberViewBackgroundColor = Palette.shared.gray3
        var grabberCornerRadius: CGFloat = 2
        var applyBackgroundColor = Palette.shared.brandPrimary
        var applyTextColor = Palette.shared.gray5
        var clearTextColor = Palette.shared.gray0
        var clearBackgroundColor = Palette.shared.clear
        var clearBorderWidth: CGFloat = 0.5
		var clearBorderColor = Palette.shared.gray3
        var buttonCornerRadius: CGFloat = 8
    }
}

final class CatalogItemSelectionViewController: UIViewController, CatalogItemSelectionControllerProtocol {
    private var presenter: CatalogItemSelectionPresenterProtocol

    private lazy var searchTextField: SearchTextField = {
        let searchTextField = SearchTextField(
            placeholder: Localization.localize("detailRequestCreation.airports.search")
        )
        searchTextField.layer.cornerRadius = self.appearance.searchTextFieldCornerRadius
        searchTextField.clipsToBounds = true
        searchTextField.delegate = self
        searchTextField.setEventHandler(for: .editingChanged) { [weak self] in
            guard let self = self else {
                return
            }
			self.searchHintLabel.isHidden = true
			self.performSearch()
        }
        return searchTextField
    }()

	private lazy var searchHintLabel: UILabel = {
		let label = UILabel()
		label.fontThemed = self.appearance.searchHintFont
		label.textColorThemed = self.appearance.searchHintColor
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		return label
	}()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.appearance.collectionItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellClass: SelectionCollectionViewCell.self)
        return collectionView
    }()

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.cancelButton, self.applyButton])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        return stackView
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        let title = Localization.localize("detailRequestCreation.cancel").attributed()
            .foregroundColor(self.appearance.clearTextColor)
            .primeFont(ofSize: 16, lineHeight: 20)
            .string()
        button.setAttributedTitle(title, for: .normal)
        button.backgroundColorThemed = self.appearance.clearBackgroundColor
        button.layer.borderWidth = self.appearance.clearBorderWidth
        button.layer.borderColorThemed = self.appearance.clearBorderColor
        button.layer.cornerRadius = self.appearance.buttonCornerRadius
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.dismiss(animated: true)
        }
        return button
    }()

    private lazy var applyButton: UIButton = {
        let button = UIButton(type: .system)
        let title = Localization.localize("selection.apply").attributed()
            .foregroundColor(self.appearance.applyTextColor)
            .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
            .string()
        button.setAttributedTitle(title, for: .normal)
        button.backgroundColorThemed = self.appearance.applyBackgroundColor
        button.layer.cornerRadius = self.appearance.buttonCornerRadius
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            guard let self = self else {
                return
            }
            self.dismiss(animated: true) {
                self.presenter.apply()
            }
        }
        return button
    }()

    private let appearance: Appearance

    var scrollView: UIScrollView? {
        self.collectionView
    }

    init(
        presenter: CatalogItemSelectionPresenterProtocol,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        self.presenter = presenter

        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.presenter.didLoad()
    }

    // MARK: - Public

    func reload() {
		self.updateSearchHint()
        self.collectionView.reloadData()
    }

	func showLoading() {
		self.view.showLoadingIndicator()
	}

	func hideLoading() {
        HUD.find(on: self.view)?.remove(animated: true)
	}

    // MARK: - Private

    private func setupView() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor
        [
            self.searchTextField,
            self.searchHintLabel,
            self.collectionView,
            self.buttonsStackView
        ].forEach(view.addSubview)

        self.searchTextField.snp.makeConstraints { make in
			make.top.equalTo(self.view.safeAreaLayoutGuide).inset(30)
            make.height.equalTo(36)
            make.leading.trailing.equalToSuperview().inset(15)
        }

		self.searchHintLabel.snp.makeConstraints { make in
			make.top.equalTo(self.searchTextField.snp.bottom).offset(10)
			make.leading.trailing.equalTo(self.searchTextField)
		}

        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.searchTextField.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
        }

        self.cancelButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.applyButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.buttonsStackView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-15)
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.equalTo(self.collectionView.snp.bottom).offset(10)
        }
    }

	private func updateSearchHint() {
		let areAnyItemsAvailable = self.presenter.numberOfItems() > 0
		self.searchHintLabel.isHidden = areAnyItemsAvailable

		if areAnyItemsAvailable {
			return
		}

		let noSearchQuery = (self.searchTextField.text ?? "").isEmpty
		//swiftlint:disable prime_font
		if noSearchQuery {
			self.searchHintLabel.text = "selection.search.invitation".localized
		} else {
			self.searchHintLabel.text = "selection.search.noResults".localized
		}
		//swiftlint:enable prime_font
	}

	private func performSearch() {
		self.presenter.search(by: self.searchTextField.text ?? "")
	}
}

extension CatalogItemSelectionViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        self.presenter.numberOfItems()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell: SelectionCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        let model = self.presenter.item(at: indexPath.item)
		cell.setup(
			value: model.name,
			description: model.description,
			isSelected: model.selected
		)
        return cell
    }
}

extension CatalogItemSelectionViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        self.searchTextField.resignFirstResponder()
        self.presenter.select(at: indexPath.item)
        self.collectionView.reloadData()
    }
}

extension CatalogItemSelectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
