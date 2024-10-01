import UIKit

enum ProfileAddNewPickerFactory {
    static func make(for values: [String], title: String?, onSelect: @escaping (Int) -> Void) -> UIViewController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        for (idx, val) in values.enumerated() {
            alert.addAction(
                .init(
                    title: val,
                    style: .default,
                    handler: { _ in onSelect(idx) }
                )
            )
        }

        alert.addAction(
            .init(title: Localization.localize("documents.form.picker.cancel"), style: .cancel, handler: nil)
        )

        return alert
    }
}
