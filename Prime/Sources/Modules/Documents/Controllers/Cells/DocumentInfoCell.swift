import UIKit

enum DocumentInfoCell {
    case typeCarousel
    case general(name: String, number: String)
    case oneColumn(title: String, text: String)

    case twoColumn(
        left: DocumentInfoTwoColumnCollectionViewCell.Column,
        right: DocumentInfoTwoColumnCollectionViewCell.Column
    )

    case emptySpace(CGFloat)
    case separator

    var cellHeight: (CGFloat) -> CGFloat {
        switch self {
        case .typeCarousel:
            return { _ in 170 }
        case .general(let name, let number):
            return { maxWidth in
                DocumentInfoGeneralCollectionViewCell.height(for: name, number: number, maxWidth: maxWidth)
            }
        case .oneColumn(let title, let text):
            return { maxWidth in
                DocumentInfoOneColumnCollectionViewCell.height(for: title, text: text, maxWidth: maxWidth)
            }
        case .twoColumn(let left, let right):
            return { maxWidth in
                DocumentInfoTwoColumnCollectionViewCell.height(for: left, rightColumn: right, maxWidth: maxWidth)
            }
        case .separator:
            return { _ in 1 }
        case .emptySpace(let val):
            return { _ in val }
        }
    }
}
