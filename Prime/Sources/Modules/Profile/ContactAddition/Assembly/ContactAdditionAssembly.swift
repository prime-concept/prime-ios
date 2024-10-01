import UIKit

enum ContactAdditionMode {
    case addition
    case edit
}

typealias ContactID = Int

final class ContactAdditionAssembly: Assembly {
    private let mode: ContactAdditionMode
    private let listType: ContactsListType
    private let id: ContactID?
    private let completion: ((Bool) -> Void)

    init(
        mode: ContactAdditionMode = .addition,
        listType: ContactsListType,
        id: ContactID? = nil,
        completion: @escaping ((Bool) -> Void)
    ) {
        self.mode = mode
        self.listType = listType
        self.id = id
        self.completion = completion
    }

    func make() -> UIViewController {
        let presenter = ContactAdditionPresenter(
            listType: self.listType,
            mode: self.mode,
            id: self.id,
            endpoint: ContactsEndpoint(authService: LocalAuthService()),
            completion: self.completion
        )
        let controller = ContactAdditionViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
