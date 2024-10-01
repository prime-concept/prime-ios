import IQKeyboardManagerSwift
import UIKit

extension DocumentEditViewController {
    struct Appearance: Codable {
        var grabberColor = Palette.shared.gray3
        var deleteButtonColor = Palette.shared.danger
        var saveButtonColor = Palette.shared.gray5
        var saveButtonBackgroundColor = Palette.shared.brandPrimary
    }
}

protocol DocumentEditViewControllerProtocol: ModalRouterSourceProtocol {
    func update(with fields: [DocumentEditFormField])
    func presentCountryPicker(
        selected: Country?,
        onSelect: @escaping (Country) -> Void
    )
    func closeFormWithSuccess()
    func showActivity()
    func hideActivity()
    func show(error: String)
    func showImagePickerController(completion: @escaping ([UIImage], Error?) -> Void)
}

final class DocumentEditViewController: UIViewController {
    private let appearance: Appearance
    private var formDataProvider: DocumentEditFormDataProvider?
    private let canDelete: Bool

    private lazy var selectionPresentationManager = FloatingControllerPresentationManager(
        context: .itemSelection,
        sourceViewController: self
    )

    private lazy var grabberView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = self.appearance.grabberColor
        view.clipsToBounds = true
        view.layer.cornerRadius = 2
        return view
    }()

    private lazy var deleteButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("documents.form.delete")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.deleteButtonColor)
            .string()

        label.clipsToBounds = true
        label.layer.cornerRadius = 8

        label.layer.borderColorThemed = Palette.shared.gray3
        label.layer.borderWidth = 1 / UIScreen.main.scale

        return label
    }()

    private lazy var saveButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("documents.form.save")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.saveButtonColor)
            .string()

        label.backgroundColorThemed = self.appearance.saveButtonBackgroundColor

        label.clipsToBounds = true
        label.layer.cornerRadius = 8

        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = Palette.shared.gray5

        collectionView.bounces = false
        collectionView.keyboardDismissMode = .onDrag

        collectionView.register(cellClass: DocumentEditAttachmentsCollectionViewCell.self)
        collectionView.register(cellClass: DocumentEditTextFieldCollectionViewCell.self)
        collectionView.register(cellClass: DocumentEditEmptySpaceCollectionViewCell.self)
        collectionView.register(cellClass: DocumentEditPickerCollectionViewCell.self)
		collectionView.register(cellClass: DocumentEditDatePickerCollectionViewCell.self)
		collectionView.register(cellClass: DocumentEditCountryPickerCollectionViewCell.self)

        return collectionView
    }()

    private lazy var buttonsContainerView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = Palette.shared.gray5
        return view
    }()

	private lazy var imagePicker = VersatileImagePicker()

    var presenter: DocumentEditPresenterProtocol?

    init(canDelete: Bool, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        self.canDelete = canDelete

        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.enable = false
    }

    // MARK: - Private

    private func setupView() {
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.view.addSubview(self.grabberView)
        self.grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(3)
        }

        if self.canDelete {
            self.buttonsContainerView.addSubview(self.deleteButton)
        }

        self.buttonsContainerView.addSubview(self.saveButton)
        self.view.addSubview(buttonsContainerView)

        self.buttonsContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.saveButton.snp.top).offset(-10)
            make.leading.trailing.bottom.equalToSuperview()
        }

        if self.canDelete {
            self.deleteButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(15)
                make.width.equalTo(self.buttonsContainerView.snp.width).offset(-2.5 - 15).multipliedBy(0.5)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-10)
                make.height.equalTo(44)
            }
        }

        self.saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(15)
            make.width.equalTo(self.buttonsContainerView.snp.width)
                .offset(self.canDelete ? -2.5 - 15 : -30)
                .multipliedBy(self.canDelete ? 0.5 : 1.0)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.height.equalTo(44)
        }

        var insets = self.collectionView.contentInset
        insets.top = 23
        insets.bottom = 64
        self.collectionView.contentInset = insets

        guard let presenter = self.presenter else {
            return
        }
        presenter.didLoad()
        self.saveButton.addTapHandler(presenter.saveForm)
        self.deleteButton.addTapHandler(presenter.deleteForm)
    }
}

extension DocumentEditViewController: DocumentEditViewControllerProtocol {
    func update(with fields: [DocumentEditFormField]) {
        let provider = DocumentEditFormDataProvider(fields: fields, presentationSource: self)

        self.formDataProvider = provider

        self.collectionView.dataSource = provider
        self.collectionView.delegate = provider

        self.collectionView.reloadData()
    }

    func closeFormWithSuccess() {
        if let hud = HUD.find(on: self.view) {
            hud.remove(animated: true) { [weak self] in
                self?.dismiss(animated: true)
            }
            return
        }
        self.dismiss(animated: true)
    }

    func showActivity() {
		self.view.showLoadingIndicator()
    }

    func hideActivity() {
        HUD.find(on: self.view)?.remove(animated: true)
    }

    func show(error: String) {
        // TODO: сделать ошибку, когда появятся в макете
        HUD.find(on: self.view)?.remove()

        let alert = UIAlertController(title: nil, message: error, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))

        self.present(alert, animated: true)
    }

	func showImagePickerController(completion: @escaping ([UIImage], Error?) -> Void) {
		let picker = self.imagePicker.viewController()
		self.imagePicker.thumbnailSmallestDimension = 75
		self.imagePicker.onResult = { images, error in
			picker.dismiss(animated: true, completion: nil)
			completion(images, error)
		}
        ModalRouter(source: self, destination: picker).route()
    }

	func presentCountryPicker(
		selected: Country?,
		onSelect: @escaping (Country) -> Void
	) {
		let assembly = CountrySelectionAssembly(
			selectedCountry: selected,
			onSelect: onSelect
		)

		let viewController = assembly.make()
		let scrollView = assembly.scrollView

		self.selectionPresentationManager.contentViewController = viewController
		self.selectionPresentationManager.track(scrollView: scrollView)
		self.selectionPresentationManager.present()
   }
}

// MARK: - DocumentEditFormDataProvider

final class DocumentEditFormDataProvider: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    private let fields: [DocumentEditFormField]
    private weak var presentationSource: UIViewController?

    init(fields: [DocumentEditFormField], presentationSource: UIViewController) {
        self.fields = fields
        self.presentationSource = presentationSource
        super.init()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.fields.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let item = self.fields[indexPath.item]

        switch item {
        case .attachments(let attachments):
            let cell: DocumentEditAttachmentsCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(
                with: attachments,
                onAdd: { [weak self] in
                    guard let self = self,
                          let controller = self.presentationSource as? DocumentEditViewController else {
                        return
                    }
                    controller.presenter?.didTapOnAttachmentsAddition()
                }
            )
            return cell
        case .textField(let model):
            let cell: DocumentEditTextFieldCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: model)
            return cell
        case .countryPicker(let model):
            let cell: DocumentEditCountryPickerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: model)
            return cell
        case .emptySpace:
            let cell: DocumentEditEmptySpaceCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell
        case .picker(let model):
            let cell: DocumentEditPickerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

            let cellUpdate: (Int) -> Void = { [weak cell] idx in
                cell?.update(with: model.values[idx])
            }
            let onTap: () -> Void = { [weak self] in
                let controller = DocumentEditPickerFactory.make(
                    for: model.values,
                    title: model.title,
                    onSelect: { idx in
                        model.onSelect(idx)
                        cellUpdate(idx)
                    }
                )

                self?.presentationSource?.present(controller, animated: true, completion: nil)
            }

            cell.configure(with: model, onTap: onTap)
            return cell
        case .datePicker(let model):
            let cell: DocumentEditDatePickerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: model)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let item = self.fields[indexPath.item]
        let height = item.height(collectionView.bounds.width)
        return CGSize(width: collectionView.bounds.width, height: height)
    }
}
