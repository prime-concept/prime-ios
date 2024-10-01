import UIKit

final class HotelFormAssembly {
    func make() -> HotelFormViewControllerProtocol {
        let presenter = HotelFormPresenter(
            graphQLEndpoint: GraphQLEndpoint(),
            localAuthService: LocalAuthService.shared
        )
        let controller = HotelFormViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
