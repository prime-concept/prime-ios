import UIKit
import SnapKit

final class CompletedTaskFeedbackView: UIView {
    var didTapOnStars: ((Int) -> Void)?
    
    private lazy var checkmarkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "send_feedback_checkmark_icon"))
		imageView.tintColorThemed = Palette.shared.brandPrimary
        imageView.backgroundColor = .clear
		imageView.make(.size, .equal, [74, 74])
        return imageView
    }()

	private lazy var checkmarkImageViewContainer = UIView { view in
		view.addSubview(self.checkmarkImageView)
		view.backgroundColorThemed = self.feedbackRatingView.backgroundColorThemed
		view.make(.size, .equal, [86, 86])
		view.layer.cornerRadius = 86 / 2
		self.checkmarkImageView.make(.center, .equalToSuperview)
	}

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = Palette.shared.brandPrimary
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.contentMode = .center
        label.textAlignment = .center
        label.textColorThemed = Palette.shared.gray5
        label.fontThemed = Palette.shared.subTitle
        return label
    }()

    private lazy var feedbackRatingView: FeedbackRatingView = {
        let view = FeedbackRatingView()
		view.imageViewContainer.isHidden = true
		view.taskTitleLabel.text = "feedback.please.rate1".localized

		with(view.starsContainer) {
			$0.worstSubscriptLabel.text = "feedback.bad".localized
			$0.bestSubscriptLabel.text = "feedback.excellent".localized
		}

		view.onRatingSet = { [weak self] rating in
			self?.didTapOnStars?(rating)
		}
        view.backgroundColorThemed = Palette.shared.gray5
        return view
    }()

    // MARK: - Override Methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }

    // MARK: - Private Methods
    private func setupUI() {
        self.setupViews()
        self.setupConstraints()
    }
    
    private func setupViews() {
		self.backgroundColorThemed = self.feedbackRatingView.backgroundColorThemed

        self.addSubviews(
			self.feedbackRatingView,
			self.headerView
		)

        self.headerView.addSubviews(
			self.titleLabel,
			self.checkmarkImageViewContainer
		)
    }
    
    private func setupConstraints() {
		self.headerView.make(.edges(except: .bottom), .equalToSuperview)
		self.headerView.make(.height, .equal, 95)

		self.titleLabel.make(.edges(except: .bottom), .equalToSuperview, [28, 0, 0])

		self.checkmarkImageViewContainer.place(under: self.titleLabel, +15)
		self.checkmarkImageViewContainer.make(.centerX, .equalToSuperview)

		self.feedbackRatingView.place(under: self.checkmarkImageViewContainer, +10)
		self.feedbackRatingView.make(.hEdges, .equalToSuperview, priorities: [.required, .init(999)])
		self.feedbackRatingView.make(.bottom, .equalToSuperview, -20)
		self.feedbackRatingView.make(.height, .equal, 108)
    }
}
