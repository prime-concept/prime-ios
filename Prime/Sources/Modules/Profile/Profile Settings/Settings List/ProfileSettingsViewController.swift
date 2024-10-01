import UIKit

extension ProfileSettingsViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var tableViewBackgroundColor = Palette.shared.gray5
    }
}

protocol ProfileSettingsViewControllerProtocol: ModalRouterSourceProtocol {}

final class ProfileSettingsViewController: UIViewController {
    private lazy var tableView = with(UITableView(frame: .zero, style: .plain)) { tableView in
        tableView.backgroundColorThemed = self.appearance.tableViewBackgroundColor
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            ProfileSettingsTableViewCell.self,
            forCellReuseIdentifier: ProfileSettingsTableViewCell.defaultReuseIdentifier
        )
		tableView.rowHeight = UITableView.automaticDimension
    }

    private let presenter: ProfileSettingsPresenterProtocol
    private let appearance: Appearance
    private let navigationTitle: String

    init(
        presenter: ProfileSettingsPresenterProtocol,
        appearance: Appearance = Theme.shared.appearance(),
        title: String
    ) {
        self.presenter = presenter
        self.appearance = appearance
        self.navigationTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override var preferredStatusBarStyle: UIStatusBarStyle {
		.lightContent
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    private func setupUI() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor

        let titleLabel = UILabel()
        titleLabel.attributedTextThemed = self.navigationTitle.attributed()
            .foregroundColor(Palette.shared.gray5)
            .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
            .string()
        self.navigationItem.titleView = titleLabel

        self.addSubviews()
        self.makeConstraints()
    }

    private func addSubviews() {
        self.view.addSubview(self.tableView)
    }

    private func makeConstraints() {
        self.tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

extension ProfileSettingsViewController: ProfileSettingsViewControllerProtocol {}

extension ProfileSettingsViewController: UITableViewDataSource, UITableViewDelegate {
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
            withIdentifier: ProfileSettingsTableViewCell.defaultReuseIdentifier
        ) as? ProfileSettingsTableViewCell else {
            fatalError("Should be of type ProfileSettingsTableViewCell")
        }
        let setting = self.presenter.setting(at: indexPath)
        cell.configure(with: setting)

		let lastRowIndex = self.presenter.numberOfRows(in: indexPath.section) - 1
		cell.separatorView.isHidden = indexPath.row == lastRowIndex
		
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.addTapHandler(feedback: .scale) { [weak self] in
            self?.presenter.didSelect(at: indexPath)
        }
    }
}
