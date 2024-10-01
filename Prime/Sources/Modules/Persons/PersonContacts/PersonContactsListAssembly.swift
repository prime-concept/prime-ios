import Foundation
import UIKit

final class PersonContactsListAssembly: Assembly {
    private let listType: ContactsListType
    private let shouldOpenInCreationMode: Bool
    private let personId: Int

    init(listType: ContactsListType, shouldOpenInCreationMode: Bool = false, personId: Int) {
        self.listType = listType
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
        self.personId = personId
    }

    func make() -> UIViewController {
        let authService = LocalAuthService()
        let presenter = PersonContactsListPresenter(
            contactsEndpoint: FamilyEndpoint(authService: authService),
            listType: self.listType,
            personId: personId
        )
        let controller = ContactsListViewController(
            presenter: presenter,
            title: self.listType.localizedTitle,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        )
        presenter.controller = controller
        return controller
    }
}
