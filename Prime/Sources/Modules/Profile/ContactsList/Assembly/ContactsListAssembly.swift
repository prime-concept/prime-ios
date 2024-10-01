import UIKit

final class ContactsListAssembly: Assembly {
    private let listType: ContactsListType
    private let shouldOpenInCreationMode: Bool

    init(listType: ContactsListType, shouldOpenInCreationMode: Bool = false) {
        self.listType = listType
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
    }

    func make() -> UIViewController {
        let authService = LocalAuthService()
        let presenter = ContactsListPresenter(
            contactsEndpoint: ContactsEndpoint(authService: authService),
            listType: self.listType
        )

        let title: String
        switch self.listType {
        case .phone:
            title = Localization.localize("profile.phones")
        case .email:
            title = Localization.localize("profile.emails")
        case .address:
            title = Localization.localize("profile.addresses")
        }
        let controller = ContactsListViewController(
            presenter: presenter,
            title: title,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        )
        presenter.controller = controller
        return controller
    }
}
