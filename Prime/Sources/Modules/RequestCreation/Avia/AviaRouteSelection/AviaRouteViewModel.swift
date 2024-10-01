struct AviaRouteViewModel: CatalogItemRepresentable {
    var name: String
    var description: String?
    var selected: Bool
    let route: AviaRoute

    init(route: AviaRoute, isSelected: Bool) {
        self.route = route
        self.name = route.title
        self.selected = isSelected
    }
}
