
import UIKit

final class DetailCalendarFileView: UIView {
	struct ViewModel {
		let title: String?
		let subtitle: String?
		let leftImage: UIImage
		let needsSeparator: Bool = true
		let onContentTap: (() -> Void)?
		let onShareTap: (() -> Void)?
	}

    //MARK: - Initialisation Methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
		self.setupView()
    }
    
    //MARK: - Private Methods
    private func setupView() {
        self.addSubviews()
        self.makeConstraints()
    }
    
    //MARK: - UI Components
	private var contentContainer: UIView!

    private lazy var leftImageView = with(UIImageView()) {
        $0.contentMode = .scaleAspectFill
    }
	
	private let titleLabel = with(UILabel()) {
		$0.textAlignment = .left
		$0.fontThemed = Palette.shared.body2
		$0.textColorThemed = Palette.shared.gray0
	}

	private let subtitleLabel = with(UILabel()) {
		$0.textAlignment = .left
		$0.fontThemed = Palette.shared.captionReg
		$0.textColorThemed = Palette.shared.gray1
	}
    
    private lazy var titlesStackView: UIStackView = {
		let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.distribution = .fillProportionally
        
        return stackView
    }()
    
    private lazy var rightButtonView: UIView = {
        let view = UIView()
        let imageView = UIImageView(image: UIImage(named: "calendar_share_icon") )
        imageView.contentMode = .center
        view.addSubview(imageView)
        imageView.make(.edges, .equalToSuperview)
        
        view.addTapHandler { [weak self] in
            self?.onShareTap?()
        }
        return view
    }()
    
    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = Palette.shared.gray3
        return view
    }()
    
    //MARK: - Seter Poperties

    private var needsSeparator: Bool = true {
        didSet {
            self.separatorView.isHidden = !needsSeparator
        }
    }
    
    private lazy var leftImageViewContainer: UIView = {
        let view = UIView()
        view.addSubview(self.leftImageView)
        self.leftImageView.snp.makeConstraints { make in
			make.width.height.equalTo(20).priority(999)
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
    private lazy var rightButtonViewContainer: UIView = {
        let view = UIView()
        view.addSubview(self.rightButtonView)
        view.backgroundColor = .clear
        
        self.rightButtonView.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.edges.equalToSuperview()
        }
        return view
    }()

	private var onShareTap: (() -> Void)?
    private var onContentTap: (() -> Void)?
    
    //MARK: - Public methods
	func setup(with viewModel: ViewModel) {
		self.subtitleLabel.isHidden = viewModel.title?.isEmpty ?? true //yes, title

		var title: String? = (viewModel.title?.isEmpty ?? true) ? nil : viewModel.title
		let subtitle: String? = (viewModel.subtitle?.isEmpty ?? true) ? nil : viewModel.subtitle

		title = title ?? subtitle

		self.titleLabel.text = title
		self.subtitleLabel.text = subtitle

		self.leftImageView.image = viewModel.leftImage
		self.needsSeparator = viewModel.needsSeparator

		self.onShareTap = viewModel.onShareTap
		self.onContentTap = viewModel.onContentTap
	}
}

extension DetailCalendarFileView {
    fileprivate func addSubviews() {
		let contentContainer = UIStackView.horizontal(
			self.leftImageViewContainer,
			.hSpacer(10),
			self.titlesStackView,
			.hSpacer(10)
		)

		contentContainer.alignment = .center

		self.contentContainer = contentContainer
		self.contentContainer.addTapHandler { [weak self] in
			self?.onContentTap?()
		}

		self.addSubviews(
			contentContainer, self.rightButtonViewContainer,
			self.separatorView
		)
    }
    
    fileprivate func makeConstraints() {
		self.contentContainer.make(.edges(except: .trailing), .equalToSuperview, [0, 15, 0])
		self.rightButtonViewContainer.make([.trailing, .centerY], .equalToSuperview, [-20, 0])
		self.contentContainer.make(.trailing, .equal, to: .leading, of: self.rightButtonViewContainer, -10)

		self.separatorView.make(.leading, .equal, to: self.titleLabel)
		self.separatorView.make([.trailing, .bottom], .equalToSuperview, [-10, 0])
    }
}
