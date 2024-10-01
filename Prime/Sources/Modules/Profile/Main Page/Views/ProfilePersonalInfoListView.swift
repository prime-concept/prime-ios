import UIKit

extension ProfilePersonalInfoListView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.clear
        var roundedCutHeaderCornerRadius: CGFloat = 10
        var roundedCutHeaderArcRadius: CGFloat = 12.5
		var customBackgroundViewColor = Palette.shared.gray5
    }
}

final class ProfilePersonalInfoListView: UIView {
    private enum Constants {
        static let numberOfSections = 2
        static let headerMaskHeight: CGFloat = 23
        static let roundedCutHeaderHeight: CGFloat = 25
    }

	var invisibleHeaderHeight: CGFloat = 160 {
		didSet {
			self.tableView.reloadData()
		}
	}

	private lazy var cutHeaderView = UIView { view in
		view.backgroundColorThemed = self.appearance.customBackgroundViewColor
	}
	
	private lazy var invisibleHeaderView = UIView { view in
		view.backgroundColorThemed = self.appearance.backgroundColor
		view.isUserInteractionEnabled = false
	}

    private lazy var tableView: UITableView = {
		let tableView = CustomBackgroundTableView(dragableHeaderView: self.cutHeaderView, style: .plain)
        tableView.backgroundColorThemed = self.appearance.backgroundColor
		tableView.backgroundView = UIView()
		tableView.backgroundView?.backgroundColorThemed = self.appearance.customBackgroundViewColor
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            ProfilePersonalInfoTableViewCell.self,
            forCellReuseIdentifier: ProfilePersonalInfoTableViewCell.defaultReuseIdentifier
        )
		tableView.rowHeight = UITableView.automaticDimension

        return tableView
    }()

    private var viewModel: ProfilePersonalInfoViewModel?
    private let appearance: Appearance
	let onSelect: (ProfilePersonalInfoCellViewModel.Item.Content) -> Void

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance(),
        onSelect: @escaping ((ProfilePersonalInfoCellViewModel.Item.Content) -> Void)
    ) {
        self.appearance = appearance
        self.onSelect = onSelect
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ProfilePersonalInfoViewModel) {
        self.viewModel = viewModel
        self.tableView.reloadData()
    }

    // MARK: - Helpers
    private func cutNotch(in view: UIView) {
        let path = UIBezierPath()
        let mask = CAShapeLayer()
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.minY)
		view.backgroundColorThemed = self.appearance.customBackgroundViewColor
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.cornerRadius = self.appearance.roundedCutHeaderCornerRadius
        path.move(to: self.bounds.origin)
        path.addArc(
            withCenter: center,
            radius: self.appearance.roundedCutHeaderArcRadius,
            startAngle: .pi,
            endAngle: 0,
            clockwise: false
        )
        path.addLine(to: CGPoint(x: self.bounds.maxX, y: self.bounds.minY))
        path.addLine(to: CGPoint(x: self.bounds.maxX, y: self.bounds.maxY))
        path.addLine(to: CGPoint(x: self.bounds.minX, y: self.bounds.maxY))
        path.close()
        mask.path = path.cgPath
        view.layer.mask = mask
    }
}

extension ProfilePersonalInfoListView: Designable {
    func addSubviews() {
        self.addSubview(self.tableView)
    }

    func makeConstraints() {
		self.tableView.make(.edges, .equalToSuperview)
    }
}

extension ProfilePersonalInfoListView: UITableViewDataSource, UITableViewDelegate {
	
    func numberOfSections(in tableView: UITableView) -> Int {
        Constants.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let cellsCount = self.viewModel?.cellViewModels.count ?? 0
        return section == 0 ? 0 : cellsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let viewModel = self.viewModel else {
			return UITableViewCell()
		}
		let cell = ProfilePersonalInfoTableViewCell(
			style: .default,
			reuseIdentifier: ProfilePersonalInfoTableViewCell.defaultReuseIdentifier
		)
        cell.setup(with: viewModel.cellViewModels[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let type = self.viewModel?.cellViewModels[indexPath.row].items.first?.content else {
            return
        }
        self.onSelect(type)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
			return self.invisibleHeaderView
        } else {
			return self.cutHeaderView
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		section == 0 ? self.invisibleHeaderHeight : Constants.roundedCutHeaderHeight
    }

	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if section != 0 {
			self.cutNotch(in: view)
		}
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let pointInTableView = self.convert(point, to: self.tableView)
		if self.invisibleHeaderView.frame.contains(pointInTableView) {
			if pointInTableView.y < self.cutHeaderView.frame.minY {
				return false
			}
		}
		return super.point(inside: point, with: event)
	}
}

extension ProfilePersonalInfoListView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let spacing: CGFloat = 23
        for cell in self.tableView.visibleCells {
            let hiddenFrameHeight = scrollView.contentOffset.y - cell.frame.origin.y + spacing
            if hiddenFrameHeight >= 0 || hiddenFrameHeight <= cell.frame.size.height {
                if let cell = cell as? ProfilePersonalInfoTableViewCell {
                    cell.maskCell(fromTop: hiddenFrameHeight)
                }
            }
        }
    }
}

private final class CustomBackgroundTableView: UITableView {
	private let dragableHeaderView: UIView

	init(dragableHeaderView: UIView, style: UITableView.Style) {
		self.dragableHeaderView = dragableHeaderView
		super.init(frame: .zero, style: style)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.backgroundView?.frame = self.bounds
		self.backgroundView?.frame.origin.y = self.dragableHeaderView.frame.maxY - 1
		self.backgroundView?.frame.size.height += 1
	}
}
