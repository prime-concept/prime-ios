import UIKit

final class PersonContactEditAssembly: Assembly {
    private let mode: ContactAdditionMode
    private let listType: ContactsListType
    private let id: ContactID?
    private let personId: Int
    private let completion: ((Bool) -> Void)

    init(
        mode: ContactAdditionMode = .addition,
        listType: ContactsListType,
        id: ContactID? = nil,
        personId: Int,
        completion: @escaping ((Bool) -> Void)
    ) {
        self.mode = mode
        self.listType = listType
        self.id = id
        self.personId = personId
        self.completion = completion
    }

    func make() -> UIViewController {
        let presenter = PersonContactEditPresenter(
            listType: self.listType,
            mode: self.mode,
            id: self.id,
            endpoint: FamilyEndpoint(authService: LocalAuthService()),
            personId: self.personId,
            completion: self.completion
        )
        let controller = ContactAdditionViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
