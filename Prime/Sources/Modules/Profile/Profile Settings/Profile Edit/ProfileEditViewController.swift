import IQKeyboardManagerSwift
import UIKit

protocol ProfileEditViewControllerProtocol: ModalRouterSourceProtocol {
    func update(with fields: [ProfileEditFormField])
    func closeFormWithSuccess()
    func showActivity()
    func hideActivity()
    func show(error: String)
}

extension ProfileEditViewController {
    struct Appearance: Codable {
        var grabberBackground = Palette.shared.gray3
        var backgroundColor = Palette.shared.gray5
        var saveBackgroundColor = Palette.shared.brandPrimary
        var saveTextColor = Palette.shared.gray1
        var changeDataTextColor = Palette.shared.gray1
    }
}

final class ProfileEditViewController: UIViewController {
    private lazy var grabberView = with(UIView()) { view in
        view.backgroundColorThemed = self.appearance.grabberBackground
        view.clipsToBounds = true
        view.layer.cornerRadius = 2
    }

    private lazy var saveButton = with(UILabel()) { view in
        view.attributedTextThemed = Localization.localize("profile.save")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 20)
            .alignment(.center)
            .foregroundColor(self.appearance.saveTextColor)
            .string()
        view.backgroundColorThemed = self.appearance.saveBackgroundColor
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.addTapHandler(self.presenter.saveForm)
    }

    private lazy var chagneDataLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedTextThemed = "profile.changeInfo.title".brandLocalized.attributed()
            .foregroundColor(self.appearance.changeDataTextColor)
            .primeFont(ofSize: 15, weight: .regular, lineHeight: 18)
            .lineBreakMode(.byWordWrapping)
            .alignment(.center)
            .string()
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var collectionView = with(
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    ) { collectionView in
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColorThemed = self.appearance.backgroundColor

        collectionView.bounces = false
        collectionView.keyboardDismissMode = .onDrag
        collectionView.isUserInteractionEnabled = Config.isPersonalDataEditingAvailable

        collectionView.register(cellClass: ProfileEditTextFieldCollectionViewCell.self)
        collectionView.register(cellClass: ProfileEditEmptySpaceCollectionViewCell.self)
    }

    private lazy var imagePicker = VersatileImagePicker()
    private let appearance: Appearance

    private let presenter: ProfileEditPresenterProtocol
    private var formDataProvider: ProfileEditFormDataProvider?

    init(presenter: ProfileEditPresenterProtocol, appearance: Appearance = Theme.shared.appearance()) {
        self.presenter = presenter
        self.appearance = appearance
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
        self.view.backgroundColorThemed = self.appearance.backgroundColor

        self.view.addSubview(self.grabberView)
        self.grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(3)
        }

        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.grabberView.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        if Config.isPersonalDataEditingAvailable {
            self.view.addSubview(self.saveButton)
            self.saveButton.snp.makeConstraints { make in
                make.height.equalTo(44)
                make.leading.trailing.equalToSuperview().inset(15)
                make.bottom.equalToSuperview().offset(-44)
            }
        } else {
            self.view.addSubview(self.chagneDataLabel)
            self.chagneDataLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(10)
                make.bottom.equalToSuperview().inset(50)
            }
        }
    }
}

extension ProfileEditViewController: ProfileEditViewControllerProtocol {
    func update(with fields: [ProfileEditFormField]) {
        let provider = ProfileEditFormDataProvider(fields: fields, presentationSource: self)
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
        alert.addAction(.init(title: "common.ok".localized.uppercased(), style: .default, handler: nil))

        self.present(alert, animated: true)
    }
}

// MARK: - ProfileEditFormDataProvider

final class ProfileEditFormDataProvider: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    private let fields: [ProfileEditFormField]
    private weak var presentationSource: UIViewController?

    init(fields: [ProfileEditFormField], presentationSource: UIViewController) {
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
        case .textField(let model):
            let cell: ProfileEditTextFieldCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: model)
            return cell
        case .datePicker(let model):
            let cell: ProfileEditTextFieldCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: model)
            return cell
        case .emptySpace:
            let cell: ProfileEditEmptySpaceCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let item = self.fields[indexPath.item]

        switch item {
        case .textField(let model):
            let cell = ProfileEditTextFieldCollectionViewCell.reference
            cell.configure(with: model)
            return self.size(for: cell, in: collectionView)
        case .datePicker(let model):
            let cell = ProfileEditTextFieldCollectionViewCell.reference
            cell.configure(with: model)
            return self.size(for: cell, in: collectionView)
        case .emptySpace:
            let cell = ProfileEditEmptySpaceCollectionViewCell.reference
            return self.size(for: cell, in: collectionView)
        }
    }

    // MARK: - Private methods

    private func size(for cell: UICollectionViewCell, in collectionView: UICollectionView) -> CGSize {
        var size = UIView.layoutFittingCompressedSize
        size.width = collectionView.bounds.size.width

        size = cell.systemLayoutSizeFitting(
            size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        return size
    }
}
