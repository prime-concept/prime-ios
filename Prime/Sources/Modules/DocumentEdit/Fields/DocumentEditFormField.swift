import UIKit

enum DocumentEditFormField {
    case attachments([DocumentEditAttachmentModel])
    case textField(DocumentEditTextFieldModel)
    case picker(DocumentEditPickerModel)
    case datePicker(DocumentEditDatePickerModel)
    case countryPicker(DocumentEditCountryPickerModel)
    case emptySpace(CGFloat)

	var height: (CGFloat) -> CGFloat {
		switch self {
			case .attachments(let models):
				return { constrainedWidth in
					let cell = DocumentEditAttachmentsCollectionViewCell.reference
					cell.configure(with: models, onAdd: {})
					return cell.sizeFor(width: constrainedWidth).height
				}
			case .textField(let model):
				return { constrainedWidth in
					let cell = DocumentEditTextFieldCollectionViewCell.reference
					cell.configure(with: model)
					return cell.sizeFor(width: constrainedWidth).height
				}
			case .picker(let model):
				return { constrainedWidth in
					let cell = DocumentEditPickerCollectionViewCell.reference
					cell.configure(with: model, onTap: {})
					return cell.sizeFor(width: constrainedWidth).height
				}
			case .datePicker(let model):
				return { constrainedWidth in
					let cell = DocumentEditDatePickerCollectionViewCell.reference
					cell.configure(with: model)
					return cell.sizeFor(width: constrainedWidth).height
				}
			case .countryPicker(let model):
				return { constrainedWidth in
					let cell = DocumentEditCountryPickerCollectionViewCell.reference
					cell.configure(with: model)
					return cell.sizeFor(width: constrainedWidth).height
				}
			case .emptySpace(let val):
				return { _ in val }
		}
	}
}
