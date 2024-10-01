import UIKit

final class PersonEditAssembly: Assembly {
    private(set) var scrollView: UIScrollView?
    private let type: PersonFormType

    init(type: PersonFormType = .newContact) {
        self.type = type
    }

    func make() -> UIViewController {
        let contact: Contact
        let canDelete: Bool

        switch type {
        case .newContact:
            contact = Contact()
            canDelete = false
        case .existing(let member):
            contact = member
            canDelete = true
        }
        let presenter = PersonEditPresenter(
            contact: contact,
            familyService: FamilyService.shared,
            contactTypes: FamilyService.shared.contactTypes ?? [])
        
        let controller = PersonEditViewController(presenter: presenter, canDelete: canDelete)
        presenter.viewController = controller
        self.scrollView = controller.scrollView
        return controller
    }


    enum PersonFormType {
        case existing(Contact)
        case newContact
    }
}
