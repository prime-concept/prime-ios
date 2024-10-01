import Foundation

struct PersonInfoViewModel {
    let personId: Int
    let shortName: String
    let fullName: String
    let birthDate: String
    let contactType: String
}

struct PersonsViewModels {
    let personInfo: PersonInfoViewModel
    let docs: ProfilePersonalInfoCellViewModel
    let contacts: ProfilePersonalInfoCellViewModel
}

extension PersonInfoViewModel {
    static func makeFamilyMemberModel(from contact: Contact) -> PersonInfoViewModel {
        let personId = contact.id ?? 0
        var name = contact.firstName ?? ""
        let fullName = (contact.lastName ?? "") + " \(contact.firstName ?? "")" + " \(contact.middleName ?? "")"
        if let lastName = contact.lastName?.first {
            name += " \(lastName)."
        }
		let birthDate = contact.birthDate?.date("yyyy-MM-dd")?.birthdayString ?? ""
        let contactType = contact.contactType?.name ?? ""
        return PersonInfoViewModel(
            personId: personId,
            shortName: name,
            fullName: fullName,
            birthDate: birthDate,
            contactType: contactType
        )
    }
}
