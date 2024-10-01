import UIKit

extension ContactsListView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.clear

        var addButtonCornerRadius: CGFloat = 8
        var addButtonBorderWidth: CGFloat = 0.5
        var addButtonBorderColor = Palette.shared.gray3
        var addButtonBackgroundColor = Palette.shared.gray5
        var addButtonFontColor = Palette.shared.gray0
    }
}

final class ContactsListView: UIView {
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColorThemed = self.appearance.backgroundColor
		tableView.tintColorThemed = Palette.shared.danger
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            ContactsListTableViewCell.self,
            forCellReuseIdentifier: ContactsListTableViewCell.defaultReuseIdentifier
        )
        return tableView
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = self.appearance.addButtonCornerRadius
        button.layer.borderWidth = self.appearance.addButtonBorderWidth
        button.layer.borderColorThemed = self.appearance.addButtonBorderColor
        button.backgroundColorThemed = self.appearance.addButtonBackgroundColor
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onTapAdd?()
        }
        return button
    }()

    private let appearance: Appearance
    private var viewModel: ContactsListViewModel?
    var onTapAdd: (() -> Void)?
    var onSelect: ((Int) -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ContactsListViewModel) {
        let attributedAddButtonTitle = viewModel.addButtonTitle.attributed()
            .foregroundColor(self.appearance.addButtonFontColor)
            .primeFont(ofSize: 16, lineHeight: 20)
            .string()
        self.addButton.setAttributedTitle(attributedAddButtonTitle, for: .normal)
        self.viewModel = viewModel
        self.tableView.reloadData()
    }
}

extension ContactsListView: Designable {
    func addSubviews() {
        [
            self.tableView,
            self.addButton
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.addButton.snp.top)
        }

        self.addButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview().inset(15)
			make.bottom.equalTo(self.safeAreaLayoutGuide).inset(10)
        }
    }
}

extension ContactsListView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel?.cellViewModels.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = self.viewModel,
              let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactsListTableViewCell.defaultReuseIdentifier,
                for: indexPath
              ) as? ContactsListTableViewCell else {
            return UITableViewCell()
        }
        cell.setup(with: viewModel.cellViewModels[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ContactsListTableViewCell.height
    }

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let viewModel = self.viewModel else {
			return
		}
		let contact = viewModel.cellViewModels[indexPath.row]
		self.onSelect?(contact.id)
	}
}
