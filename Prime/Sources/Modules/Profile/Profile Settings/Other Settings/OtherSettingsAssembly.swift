import UIKit

final class OtherSettingsAssembly: Assembly {
    func make() -> UIViewController {
        let presenter = OtherSettingsPresenter()
        let controller = OtherSettingsViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}

