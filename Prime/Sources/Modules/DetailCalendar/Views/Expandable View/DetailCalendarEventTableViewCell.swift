import UIKit

final class DetailCalendarEventTableViewCell: UITableViewCell, Reusable {
	struct ViewModel {
		let event: CalendarRequestItemViewModel
		let files: [DetailCalendarFileView.ViewModel]
		let isExpanded: Bool
	}

	var willChangeSize: (() -> Void)?
	var didChangeSize: (() -> Void)?
	var onExpand: ((Bool) -> Void)?

	private var filesHeight: CGFloat = 0
	private var cellHeightConstraint: NSLayoutConstraint!

	private static let eventHeight: CGFloat = 10 + DetailCalendarEventView.defaultHeight + 10

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	private lazy var eventView = with(DetailCalendarEventView()) { view in
		view.onExpandTap = { [weak self] isExpanded in
			self?.isExpanded = isExpanded
			self?.onExpand?(isExpanded)
		}
	}

	private lazy var filesStackView = UIStackView.vertical([])
	private lazy var filesCountView = DetailCalendarFilesCountView()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = Palette.shared.gray3
        return view
    }()
    
    private lazy var mainContentView: UIView = {
        let stackView = UIView()

		stackView.clipsToBounds = true
		stackView.layer.borderWidth = 1.0
		stackView.layer.cornerRadius = 8.0
		stackView.backgroundColorThemed = Palette.shared.gray5
		stackView.layer.borderColorThemed = Palette.shared.gray3

        return stackView
    }()

	private var isExpanded = false {
		didSet {
			self.expandFilesList(isExpanded)
		}
	}
    
    // MARK: - Public Methods
	func setup(with viewModel: ViewModel) {
		self.eventView.setup(with: viewModel.event)
		self.prepareFileViews(with: viewModel.files)

		if self.isExpanded != viewModel.isExpanded {
			UIView.performWithoutAnimation {
				self.eventView.isExpanded = viewModel.isExpanded
				self.isExpanded = viewModel.isExpanded
			}
		}

		self.setNeedsLayout()
	}

	private func prepareFileViews(with models: [DetailCalendarFileView.ViewModel]) {
		self.filesStackView.removeArrangedSubviews()

		if models.isEmpty { return }

		self.filesCountView.setup(count: "\(models.count)")
		self.filesStackView.addArrangedSubview(self.filesCountView)

		for file in models {
			let fileView = DetailCalendarFileView()
			fileView.make(.height, .equal, 55, priority: .init(999))
			fileView.setup(with: file)
			self.filesStackView.addArrangedSubview(fileView)
		}
	}

	private func expandFilesList(_ isExpanded: Bool) {
		self.willChangeSize?()

		self.filesHeight = self.filesStackView.sizeFor(width: self.bounds.width).height

		let cellHeight = isExpanded ? (Self.eventHeight + self.filesHeight) : Self.eventHeight
		self.cellHeightConstraint.constant = cellHeight

		if !isExpanded {
			self.setNeedsLayout()
			UIView.animate(withDuration: CATransaction.animationDuration()) {
				self.layoutIfNeeded()
			}
		}

		self.didChangeSize?()
    }
}

extension DetailCalendarEventTableViewCell {
    func setupView() {
        self.backgroundColorThemed = Palette.shared.gray5
        self.selectionStyle = .none
    }
    
    func addSubviews() {
		let eventView = self.eventView.inset([10, 10, -10, -10])

		self.mainContentView.addSubviews(
			eventView,
			self.separatorView,
			self.filesStackView
		)

		self.separatorView.place(under: eventView)
		self.filesStackView.place(under: self.separatorView)

		eventView.make(.height, .equal, Self.eventHeight)
		eventView.make(.edges(except: .bottom), .equalToSuperview)

		self.separatorView.make(.hEdges, .equalToSuperview)
		self.filesStackView.make(.hEdges, .equalToSuperview)

		self.contentView.addSubviews(
			self.mainContentView
		)
    }
    
    func makeConstraints() {
		self.mainContentView.make(
			.edges, .equalToSuperview, [0, 15, -10, -15],
			priorities: [.required, .required, .init(999), .init(999)]
		)

		self.cellHeightConstraint = self.mainContentView.make(.height, .equal, Self.eventHeight)
    }
}
