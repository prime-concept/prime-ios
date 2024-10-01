import Foundation
import PassKit
import PromiseKit
import UIKit

extension Notification.Name {
	static let profileDataFetched = Notification.Name("profileDataFetched")
	static let profileDataRequested = Notification.Name("profileDataRequested")
    static let profileAskedToBeDismissed = Notification.Name("profileAskedToBeDismissed")
}

protocol ProfilePresenterProtocol {
    func didAppear()

    func fetchProfileIfNeeded()
	func didSelect(_ type: ProfilePersonalInfoCellViewModel.Item.Content)
    func updateWalletPassKitControlsIfPossible()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var controller: ProfileViewControllerProtocol?
    private let profileEndpoint: ProfileEndpointProtocol
    private let docsEndpoint: DocumentsEndpointProtocol
    private let discountsEndpoint: DiscountsEndpointProtocol
    private let contactsEndpoint: ContactsEndpointProtocol
    private let analyticsReporter: AnalyticsReportingServiceProtocol
    private let walletService: WalletServiceProtocol
    private let onProfileFetched: ((Profile) -> Void)

    private let pkPassLibrary = PKPassLibrary()
    private var pkPass: PKPass?

	@ThreadSafe
	private var mayLoadProfile = true

    private var didSetupDeeplinkHandler = false

    init(
        profileEndpoint: ProfileEndpointProtocol,
        docsEndpoint: DocumentsEndpointProtocol,
        discountsEndpoint: DiscountsEndpointProtocol,
        contactsEndpoint: ContactsEndpointProtocol,
        analyticsReporter: AnalyticsReportingServiceProtocol,
        walletService: WalletServiceProtocol,
        onProfileFetched: @escaping ((Profile) -> Void)
    ) {
        self.profileEndpoint = profileEndpoint
        self.docsEndpoint = docsEndpoint
        self.discountsEndpoint = discountsEndpoint
        self.contactsEndpoint = contactsEndpoint
        self.analyticsReporter = analyticsReporter
        self.walletService = walletService
        self.onProfileFetched = onProfileFetched

		self.setupNotifications()
    }

    func didAppear() {
        if self.didSetupDeeplinkHandler { return }
        self.didSetupDeeplinkHandler = true

        Notification.onReceive(.shouldProcessDeeplink) { [weak self] notification in
            self?.processDeeplinkIfNeeded(notification)
        }
    }

    func fetchProfileIfNeeded() {
		guard self.mayLoadProfile else {
			return
		}
		self.mayLoadProfile = false

		self.getPKPass()
		self.fetchProfileData()
    }

    func didSelect(_ type: ProfilePersonalInfoCellViewModel.Item.Content) {}

    func updateWalletPassKitControlsIfPossible() {
		guard self.mayLoadProfile else {
			return
		}

		self.updateWalletPassKitControls()
    }

	private func updateWalletPassKitControls() {
        guard let pass = self.pkPass, UserDefaults[bool: "addToWalletEnabled"] else {
			self.controller?.setAddToWalletButton(hidden: true)
			self.controller?.setAddedToWalletView(hidden: true)
			return
		}

		let passAlreadyAdded = self.pkPassLibrary.containsPass(pass)
		self.controller?.setAddToWalletButton(hidden: passAlreadyAdded)
		self.controller?.setAddedToWalletView(hidden: !passAlreadyAdded)
	}

    // MARK: - Helpers

	private func setupNotifications() {
		Notification.onReceive(
			.profileDocumentsChanged,
			.profileContactsChanged,
			.profileCardsChanged,
			.profilePersonsChanged
		) { [weak self] notification in
			self?.profileDataChanged(notification)
		}

		Notification.onReceive(.profileDataRequested) { [weak self] _ in
			self?.fetchProfileIfNeeded()
		}
    }
	
	@objc
	private func profileDataChanged(_ notification: Notification) {
		self.fetchProfileData()
	}

	private func getPKPass() {
		DispatchQueue.global(qos: .userInitiated).promise {
			self.walletService.getPKPass()
		}.done { pkPass in
			self.pkPass = pkPass
		}.ensure { [weak self] in
			self?.updateWalletPassKitControls()
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) getPKPass failed",
					parameters: error.asDictionary
				)
			DebugUtils.shared.log(sender: self, "Failed to load pkPass")
		}
	}

	private lazy var profileViewModel = ProfileViewModel(
		cardViewModel: self.makeProfileCardViewModel(for : LocalAuthService.shared.user!),
		personalInfoViewModel: self.makePresonalInfoViewModel(),
		loadingSucceeded: false
	)

    private func fetchProfileData() {
		if LocalAuthService.shared.user == nil {
			return
		}

		self.controller?.showLoading()

		self.controller?.setup(with: self.profileViewModel)

		let profilePromise = DispatchQueue.global(qos: .userInitiated).promise {
			self.profileEndpoint.getProfile().promise
		}

		let discountsPromise = DispatchQueue.global(qos: .userInitiated).promise {
			self.discountsEndpoint.getDiscountCards().promise
        }

        let docsPromise = DispatchQueue.global(qos: .userInitiated).promise {
			self.docsEndpoint.getDocs().promise
        }

        let contactsPromise = DispatchQueue.global(qos: .userInitiated).promise {
			self.contactsEndpoint.getContacts().promise
        }

        let phonesPromise = DispatchQueue.global(qos: .userInitiated).promise {
			self.contactsEndpoint.getPhones().promise
        }

		let emailsPromise = DispatchQueue.global(qos: .userInitiated).promise {
			self.contactsEndpoint.getEmails().promise
		}

		let addressesPromise = DispatchQueue.global(qos: .userInitiated).promise {
			self.contactsEndpoint.getAddresses().promise
        }

        when(
            fulfilled:
                profilePromise,
                discountsPromise,
                docsPromise,
                contactsPromise
        ).done { [weak self] profile, discounts, docs, contacts in
            guard let self = self else {
                return
            }

			self.onProfileFetched(profile)

			let cardViewModel = self.makeProfileCardViewModel(for : profile)

			self.profileViewModel = ProfileViewModel(
				cardViewModel: cardViewModel,
				personalInfoViewModel: self.makePresonalInfoViewModel(
					with: discounts.data ?? [],
					docs: docs.data ?? [],
					phones: [],
					contacts: contacts.data ?? []
				),
                loadingSucceeded: true
			)

            when(fulfilled: phonesPromise, emailsPromise, addressesPromise).done { phones, emails, addresses in
				self.profileViewModel = ProfileViewModel(
                    cardViewModel: cardViewModel,
                    personalInfoViewModel: self.makePresonalInfoViewModel(
						with: discounts.data ?? [],
                        docs: docs.data ?? [],
                        phones: phones.data ?? [],
                        emails: emails.data ?? [],
                        contacts: contacts.data ?? [],
                        addresses: addresses.data ?? []
                    ),
                    loadingSucceeded: true
                )
            }
			.ensure {
				self.mayLoadProfile = true
				NotificationCenter.default.post(name: .profileDataFetched, object: nil)
			}.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) one of data promises failed",
						parameters: error.asDictionary
					)

				if self.controller?.view?.window != nil {
					AlertPresenter.alertCommonError(error)
				}
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING EMAILS/ADDRESSES:\(error.localizedDescription)")
			}.finally {
				self.controller?.setup(with: self.profileViewModel)
				self.controller?.hideLoading()
			}
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) one of data promises failed",
					parameters: error.asDictionary
				)

			self.mayLoadProfile = true
			self.controller?.hideLoading()
			self.controller?.setup(with: self.profileViewModel)
			if self.controller?.view?.window != nil {
				AlertPresenter.alertCommonError(error)
			}
		}
    }

    private func makePresonalInfoViewModel(
        with discounts: [Discount] = [],
        docs: [Document] = [],
        phones: [Phone] = [],
        emails: [Email] = [],
        contacts: [Contact] = [],
        addresses: [Address] = []
    ) -> ProfilePersonalInfoViewModel {
        let meSectionCellViewModel = self.handleMeSection()
        let cardsCellViewModel = self.handle(discounts: discounts)
        
        let viewModel = ProfilePersonalInfoViewModel(
            cellViewModels: [
                meSectionCellViewModel,
                cardsCellViewModel
            ]
        )
        return viewModel
    }

    private func makeProfileCardViewModel(for profile: Profile) -> ProfileCardViewModel {
        let lastName = profile.lastName ?? ""
        let firstName = profile.firstName ?? ""
        let name = lastName + " " + firstName

        var expiryDate: Date? = nil
        if let expiryDateString = profile.expiryDate {
            expiryDate = expiryDateString.date("yy-MM-dd")
        }

        var isAddedToWallet = false
		if let pkPass = self.pkPass, self.pkPassLibrary.containsPass(pkPass) {
            isAddedToWallet = true
        }

        let cardViewModel = ProfileCardViewModel(
            name: name.uppercased(),
            userName: profile.clubCard ?? "",
            expiryDate: expiryDate,
            clubCard: profile.clubCard,
            isAddedToWallet: isAddedToWallet,
            addCardTap: { [weak self] in
                self?.analyticsReporter.tappedAddToWallet()
                self?.requestToAddCardToWallet()
            }
        )
        return cardViewModel
    }

    private func handle(discounts: [Discount]) -> ProfilePersonalInfoCellViewModel {
		let discountsImages = discounts.map { $0.type?.logoUrl ?? "" }
		let discountsColors = discounts.map { UIColor.init(hexString: $0.type?.color ?? "") ?? .clear }

		let count = discounts.count
		let items: [ProfilePersonalInfoCellViewModel.Item]
        // swiftlint:disable:next empty_count
		if count == 0 {
			let empty = self.makeEmptyContentItem(
				with: "profile.addLoyaltyCards".localized,
				subtitle: "profile.emptyDescription".localized
			)
			items = [empty]
		} else {
			items = [
				.init(
					title: "profile.loyalty".localized,
					count: "",
					content: .cards(discountsImages, discountsColors)
				)
			].filter { $0.count != "0" }
		}

		let viewModel = ProfilePersonalInfoCellViewModel(
			title: "profile.cards".localized,
			count: "",
			items: items,
			supportedItemNames: ["profile.loyalty.cards".localized],
			onCountTap: { [weak self] in
				self?.controller?.presentCards(index: 0, shouldOpenInCreationMode: false)
			},
			openDetailsOnTabWithIndex: { [weak self] inx, flag in
				self?.controller?.presentCards(index: inx, shouldOpenInCreationMode: flag)
			}
		)

        return viewModel
    }
    
    private func handleMeSection() -> ProfilePersonalInfoCellViewModel {
        let items: [ProfilePersonalInfoCellViewModel.Item]
        
        items = [
            .init(
                title: "profile.phones".localized,
                content: .plain(UIImage(named: "profile_phone_icon"))
            ),
            .init(
                title: "profile.family".localized,
                content: .plain(UIImage(named: "profile_family_icon"))
            ),
            .init(
                title: "profile.documents".localized,
                content: .plain(UIImage(named: "profile_docs_icon"))
            )
        ]
        
        let viewModel = ProfilePersonalInfoCellViewModel(
            title: Localization.localize("profile.me".localized),
            items: items,
            supportedItemNames: [
                "profile.phones".localized,
                "profile.family".localized,
                "profile.documents".localized
            ],
            openDetailsOnTabWithIndex: { [weak self] idx, flag in
                self?.controller?.didTapOnMeSection(index: idx, shouldOpenInCreationMode: flag)
            }
        )

        return viewModel
    }
    
	private func makeEmptyContentItem(with title: String, subtitle: String) -> ProfilePersonalInfoCellViewModel.Item {
		ProfilePersonalInfoCellViewModel.Item(
			title: "",
			count: "0",
			content: .empty(title, subtitle)
		)
	}

    private func requestToAddCardToWallet() {
        guard let pass = self.pkPass else {
            preconditionFailure("No pkPass to add to wallet!!!")
        }

        if self.pkPassLibrary.containsPass(pass) {
            return
        }

		self.controller?.presentPKPassAddition(with: pass)
    }

    private func processDeeplinkIfNeeded(_ notification: Notification) {
        let deeplink = notification.userInfo?["deeplink"] as? DeeplinkService.Deeplink
        guard let deeplink else { return }

        if case .profile = deeplink {
            return
        }

        Notification.post(.profileAskedToBeDismissed)
    }
}
