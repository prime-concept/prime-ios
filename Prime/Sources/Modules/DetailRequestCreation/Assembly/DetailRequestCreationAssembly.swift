import UIKit

final class DetailRequestCreationAssembly: Assembly {
    private let typeID: Int
    private var completion: ((Int?) -> Void)?

    init(typeID: Int, completion: ((Int?) -> Void)? = nil) {
        self.typeID = typeID
        self.completion = completion
    }

    func make() -> UIViewController {
        let presenter = DetailRequestCreationPresenter(
            typeID: self.typeID,
            graphQLEndpoint: GraphQLEndpoint()
        )
        let controller = DetailRequestCreationViewController(presenter: presenter)
        controller.completion = self.completion
        presenter.controller = controller
        return controller
    }
}
