import Foundation

struct Document: Codable {
    var id: Int?
    var documentType: DocumentType?
    var firstName: String?
    var middleName: String?
    var lastName: String?
    var citizenship: String?
    var documentNumber: String?
    var issueDate: String?
    var issuedAt: String?
    var expiryDate: String?
    var birthDate: String?
    var birthPlace: String?
    var authority: String?
    var authorityId: String?
    var countryCode: String?
    var countryName: String?
    var visaTypeId: VisaType?
    var visaTypeName: String?
    var comment: String?
    var relatedPassport: AttachedDocument?
    var relatedVisas: [AttachedDocument]?
    var domicile: String?
    var categoryOfVehicleId: Int?
    var categoryOfVehicleName: String?
    var insuranceCompany: String?
    var coverage: String?
}

enum DocumentType: Int, Codable {
	init(rawValue: Int) {
		switch rawValue {
			case 1:
				self = .passport
			case 2:
				self = .visa
			default:
				self = .other
		}
	}

    case passport = 1
    case visa = 2
    case other = 3
}

struct AttachedDocument: Codable {
    let id: Int
    let documentType: DocumentType?
    let documentNumber: String?
}

struct Documents: Codable {
    let data: [Document]?
}

enum VisaType: Int, Codable, CaseIterable, Equatable {
    case single = 2
	case multiple = 3
	case singleSchengen = 4
    case multipleSchengen = 5

    var title: String {
        Localization.localize("documents.visa.type.\(self.rawValue)")
    }
}
