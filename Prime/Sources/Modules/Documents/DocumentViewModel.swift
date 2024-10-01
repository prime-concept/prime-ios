import Foundation

struct DocumentViewModel {
    let cells: [DocumentInfoCell]

	// Непонятно, как определять паспорта из апи
    var documentType: DocumentTypeCollectionViewCell.DocumentType
}

extension DocumentViewModel {
    static func makeAsPassport(from document: Document) -> DocumentViewModel {
        var cells: [DocumentInfoCell] = []

        let name = [document.lastName, document.firstName, document.middleName]
            .compactMap { $0 }
            .joined(separator: " ")
        cells.append(.general(name: name, number: document.documentNumber ?? ""))

        cells.append(.emptySpace(15))
        cells.append(.separator)
        cells.append(.emptySpace(20))

        let placeOfBirth = document.birthPlace
            .flatMap { (Localization.localize("documents.form.birthPlace"), $0) }
        let dateOfBirth = document.birthDate
            .flatMap { (Localization.localize("documents.form.birthDate"), $0) }
        Self.addTwoOrOneColumn(left: placeOfBirth, right: dateOfBirth, cells: &cells)

        Self.addOneColumn(
            title: Localization.localize("documents.form.issuingAuthority"),
            text: document.authority,
            cells: &cells
        )

        let dateOfIssue = document.issueDate
            .flatMap { (Localization.localize("documents.form.dateOfIssue"), $0) }
        let countryOfIssue = document.countryName
            .flatMap { (Localization.localize("documents.form.issuingCountry"), $0) }
        Self.addTwoOrOneColumn(left: dateOfIssue, right: countryOfIssue, cells: &cells)

        let authorityId = document.authorityId
            .flatMap { (Localization.localize("documents.form.authorityId"), $0) }
        let nationality = document.citizenship
            .flatMap { (Localization.localize("documents.form.nationality"), $0) }
        Self.addTwoOrOneColumn(left: authorityId, right: nationality, cells: &cells)

		
		return DocumentViewModel(cells: cells, documentType: .russianPassport)
    }

    static func makeAsVisa(from document: Document) -> DocumentViewModel {
        var cells: [DocumentInfoCell] = []

        let name = [document.lastName, document.firstName, document.middleName]
            .compactMap { $0 }
            .joined(separator: " ")
        cells.append(.general(name: name, number: document.documentNumber ?? ""))

        cells.append(.emptySpace(15))
        cells.append(.separator)
        cells.append(.emptySpace(20))

        let visaType = document.visaTypeName
            .flatMap { (Localization.localize("documents.form.visaType"), "\($0)") }
        let countryOfIssue = document.countryName
            .flatMap { (Localization.localize("documents.form.issuingCountry"), $0) }
        Self.addTwoOrOneColumn(left: visaType, right: countryOfIssue, cells: &cells)

        Self.addOneColumn(
            title: Localization.localize("documents.form.passport"),
            text: document.relatedPassport?.documentNumber,
            cells: &cells
        )

        let dateOfIssue = document.issueDate
            .flatMap { (Localization.localize("documents.form.dateOfIssue"), $0) }
        let dateOfExpiry = document.expiryDate
            .flatMap { (Localization.localize("documents.form.dateOfExpiry"), $0) }
        Self.addTwoOrOneColumn(left: dateOfIssue, right: dateOfExpiry, cells: &cells)

		return DocumentViewModel(cells: cells, documentType: .visa)
    }

    private static func addOneColumn(title: String, text: String?, cells: inout [DocumentInfoCell]) {
        if let text = text {
            cells.append(.oneColumn(title: title, text: text))
            cells.append(.emptySpace(20))
        }
    }

    private static func addTwoOrOneColumn(
        left: DocumentInfoTwoColumnCollectionViewCell.Column?,
        right: DocumentInfoTwoColumnCollectionViewCell.Column?,
        cells: inout [DocumentInfoCell]
    ) {
        if let left = left {
            if let right = right {
                cells.append(.twoColumn(left: left, right: right))
                cells.append(.emptySpace(20))
            } else {
                cells.append(.oneColumn(title: left.0, text: left.1))
                cells.append(.emptySpace(20))
            }
        } else if let right = right {
            cells.append(.oneColumn(title: right.0, text: right.1))
            cells.append(.emptySpace(20))
        }
    }
}
