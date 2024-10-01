import UIKit

final class PinCodeAssembly: Assembly {
    // Этот блок передается в комплишен, и вызывается клиентским кодом,
    // если приходит ошибка авторизации при корректном пинкоде (совпавшем с сохраненным).
    // Это происходит, когда пинкод был изменен на другом устройстве.
    // Тогда мы кидаем юзера на создание нового пинкода.
    typealias ResetPinBlock = () -> Void

    private let mode: PinCodeMode
    private let phone: String?
    private let completion: ((Bool, PinCodeMode, ResetPinBlock?) -> Void)
    private let shouldDismiss: Bool

    init(
        mode: PinCodeMode,
        phone: String? = nil,
        shouldDismiss: Bool = false,
        completion: @escaping ((Bool, PinCodeMode, ResetPinBlock?) -> Void)
    ) {
        self.mode = mode
        self.phone = phone
        self.shouldDismiss = shouldDismiss
        self.completion = completion
    }

    func make() -> UIViewController {
        let presenter = PinCodePresenter(
            mode: self.mode,
            phone: self.phone,
            authEndpoint: AuthEndpoint(),
            localAuthService: LocalAuthService.shared,
            shouldDismiss: self.shouldDismiss,
            completion: self.completion
        )

        let view = PinCodeViewController(presenter: presenter)
        presenter.view = view

        return view
    }
}
