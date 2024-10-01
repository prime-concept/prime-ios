import UIKit

protocol ContactPrimeViewProtocol: ModalRouterSourceProtocol {
    func updateUserInteraction(_ isEnabled: Bool)

	func notifyCallRequested()
	func notifyCallRequestFailed()
}

final class ContactPrimeViewController: UIViewController {
    private lazy var contactPrimeView = ContactPrimeView()
    private var presenter: ContactPrimePresenterProtocol

	var onDismiss: (() -> Void)?

	private lazy var notificationView = with(ContactPrimeNotificationView()) { view in
		view.onClose = { [weak self] in
			self?.hideNotification()
		}
	}

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    init(presenter: ContactPrimePresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	private var notificationViewBottom: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)

		self.view.addSubview(self.contactPrimeView)
		self.contactPrimeView.make(.edges, .equalToSuperview)

        self.setupActions()

		self.view.addSubview(self.notificationView)
		self.view.make(.size, .equal, [UIScreen.main.bounds.width, UIScreen.main.bounds.height])

		self.notificationView.make(.hEdges, .equalToSuperview, [5, -5])

		self.notificationViewBottom = self.notificationView.make(
			.bottom, .equal, to: .top, of: self.view
		)
    }

    private func setupActions() {
        self.contactPrimeView.onClose = { [weak self] in
			self?.onDismiss?()
            self?.dismiss(animated: true)
        }
        self.contactPrimeView.onCallButtonTap = { [weak self] in
            self?.presenter.callPrime()
        }
        self.contactPrimeView.onCallBackButtonTap = { [weak self] in
            self?.presenter.callBack()
        }
        self.contactPrimeView.onGoToSiteButtonTap = { [weak self] in
            self?.presenter.goToSite()
        }
    }

	private func showNotification() {
		let showBlock = {
			self.notificationViewBottom?.constant =
				self.notificationView.bounds.height
				+ self.view.safeAreaInsets.top
				+ 15

			self.view.setNeedsLayout()
			UIView.animate(withDuration: 0.3) {
				self.view.layoutIfNeeded()
			}
		}

		if self.notificationViewBottom?.constant ?? 0 == 0 {
			showBlock()
			return
		}

		self.hideNotification(showBlock)
	}

	private func hideNotification(_ completion: (() -> Void)? = nil) {
		self.notificationViewBottom?.constant = 0

		self.view.setNeedsLayout()
		UIView.animate(withDuration: 0.3, animations: {
			self.view.layoutIfNeeded()
		}) { _ in
			completion?()
		}
	}
}

extension ContactPrimeViewController: ContactPrimeViewProtocol {
    func updateUserInteraction(_ isEnabled: Bool) {
        self.view.isUserInteractionEnabled = isEnabled
    }

	func notifyCallRequested() {
		self.notificationView.update(with: .init(
			iconName: "onboard-info-phone",
			title: "contact.we.will.call.you.back.title".localized,
			message: "contact.we.will.call.you.back.message".localized
		))

		self.notificationView.setNeedsLayout()
		self.notificationView.layoutIfNeeded()

		self.showNotification()
	}

	func notifyCallRequestFailed() {
		self.notificationView.update(with: .init(
			iconName: "onboard-info-error",
			title: "contact.we.will.call.you.back.error.title".localized,
			message: "contact.we.will.call.you.back.error.message".localized
		))

		self.notificationView.setNeedsLayout()
		self.notificationView.layoutIfNeeded()

		self.showNotification()
	}
}
