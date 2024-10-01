import UIKit

protocol OtherSettingsViewControllerProtocol: AnyObject {
	func alert(message: String)
}

final class OtherSettingsViewController: UIViewController {
    private lazy var grabberView = with(UIView()) { view in
        view.backgroundColorThemed = Palette.shared.gray3
        view.clipsToBounds = true
        view.layer.cornerRadius = 2
    }

    private lazy var tableView = with(UITableView(frame: .zero, style: .plain)) { tableView in
        tableView.backgroundColorThemed = Palette.shared.gray5
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            OtherSettingsTableViewCell.self,
            forCellReuseIdentifier: OtherSettingsTableViewCell.defaultReuseIdentifier
        )
    }

    private lazy var saveButton = with(UILabel()) { view in
        view.attributedTextThemed = Localization.localize("profile.save")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(Palette.shared.gray5)
            .string()
        view.backgroundColorThemed = Palette.shared.brandPrimary
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.addTapHandler(feedback: .scale, self.presenter.saveForm)
		view.isHidden = true
    }

    private let presenter: OtherSettingsPresenterProtocol

    init(presenter: OtherSettingsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    private func setupUI() {
        self.view.backgroundColorThemed = Palette.shared.gray5

        self.addSubviews()
        self.makeConstraints()
    }

    private func addSubviews() {
        [
            self.grabberView,
            self.tableView,
            self.saveButton
        ].forEach(self.view.addSubview)
    }

    private func makeConstraints() {
        self.grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(3)
        }

        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.grabberView.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.saveButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-44)
        }
    }

	func alert(message: String) {
		self.showLoadingIndicator()
		delay(1) {
			self.hideLoadingIndicator()
			AlertPresenter.alert(message: message, actionTitle: "common.ok".localized)
		}
	}
}

extension OtherSettingsViewController: OtherSettingsViewControllerProtocol {}

extension OtherSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        self.presenter.numberOfRows(in: section)
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OtherSettingsTableViewCell.defaultReuseIdentifier
        ) as? OtherSettingsTableViewCell else {
            fatalError("Should be of type OtherSettingsTableViewCell")
        }
        let setting = self.presenter.setting(at: indexPath)
        cell.configure(with: setting)
        return cell
    }
}
