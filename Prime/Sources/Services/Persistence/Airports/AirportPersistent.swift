import Foundation
import RealmSwift

final class AirportPersistent: Object {
    @objc dynamic var altCountryName: String = ""
    @objc dynamic var altCityName: String = ""
    @objc dynamic var isHub: Bool = false
    @objc dynamic var altName: String?
    @objc dynamic var city: String = ""
    @objc dynamic var code: String = ""
    @objc dynamic var country: String = ""
    @objc dynamic var deleted: Bool = false
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var updatedAt: Int = 0
    @objc dynamic var cityId: Int = 0
    @objc dynamic var vipLoungeCost: String?

    var latitude = RealmOptional<Double>()
    var longitude = RealmOptional<Double>()

    override class func primaryKey() -> String? { "id" }
}

extension Airport: RealmObjectConvertible {
    typealias RealmObjectType = AirportPersistent

    init(realmObject: AirportPersistent) {
        self.altCountryName = realmObject.altCountryName
        self.altCityName = realmObject.altCityName
        self.isHub = realmObject.isHub
        self.altName = realmObject.altName
        self.city = realmObject.city
        self.code = realmObject.code
        self.country = realmObject.country
        self.deleted = realmObject.deleted
        self.id = realmObject.id
        self.name = realmObject.name
        self.updatedAt = realmObject.updatedAt
        self.latitude = realmObject.latitude.value
        self.longitude = realmObject.longitude.value
        self.cityId = realmObject.cityId
        self.vipLoungeCost = realmObject.vipLoungeCost
    }

    var realmObject: AirportPersistent { AirportPersistent(plainObject: self) }
}

extension AirportPersistent {
    convenience init(plainObject: Airport) {
        self.init()
        self.altCountryName = plainObject.altCountryName
        self.altCityName = plainObject.altCityName
        self.isHub = plainObject.isHub^
        self.altName = plainObject.altName
        self.city = plainObject.city
        self.code = plainObject.code
        self.country = plainObject.country
        self.deleted = plainObject.deleted
        self.id = plainObject.id
        self.name = plainObject.name
        self.updatedAt = plainObject.updatedAt
        self.latitude = RealmOptional(plainObject.latitude)
        self.longitude = RealmOptional(plainObject.longitude)
        self.cityId = plainObject.cityId
        self.vipLoungeCost = plainObject.vipLoungeCost
    }
}
