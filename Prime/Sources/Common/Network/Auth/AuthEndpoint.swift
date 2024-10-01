import Foundation
import PromiseKit
import Alamofire

protocol AuthEndpointProtocol {
	func logout() -> EndpointResponse<LogoutResponse>

    func register(phone: String) -> EndpointResponse<EmptyResponse>
	func check(phone: String) -> EndpointResponse<EmptyResponse>
    func verify(phone: String, key: String) -> EndpointResponse<Profile>

	func refreshOauthToken(username: String, code: String) -> EndpointResponse<AccessToken>
    func fetchOauthToken(username: String, code: String) -> EndpointResponse<AccessToken>
    func set(password: String, phone: String) -> EndpointResponse<EmptyResponse>
    func callBack(to phone: String) -> EndpointResponse<EmptyResponse>

	//PrimeClub
    func verify(card: String) -> EndpointResponse<EmptyResponse>
    func register(card: String, surname: String, name: String, phone: String, email: String) -> EndpointResponse<EmptyResponse>
}

final class AuthEndpoint: Endpoint, PrimeEndpointProtocol, AuthEndpointProtocol {
	static let logout = "/logout"
	static let fetchOauthToken = "/oauth/token"
	static let setPassword = "/mobile/password"

    private static let registerEndpoint = "/mobile/register"
    private static let verifyEndpoint = "/mobile/verify"
    private static let callBack = "/mobile/callback"
    private static let checkPhone = "/mobile/checkPhone"
    private static let varifyCard = "/mobile/card"
    private static let registerProfile = "/mobile/profile"

	override var needsTokenToExecuteRequests: Bool {
		false
	}

    override var usesResponseCache: Bool {
        false
    }

    convenience init() {
        self.init(basePath: PrimeEndpoint.endpoint)
    }

    func verify(phone: String, key: String) -> EndpointResponse<Profile> {
        var params = self.paramsWithCredentials
        params["phone"] = phone
        params["key"] = key

        let signatureSeed = "\(self.paramsString)\(phone)\(key)"
		params.insertSignature(generatedFrom: signatureSeed)

        return self.create(endpoint: Self.verifyEndpoint, parameters: params)
    }

    func verify(card: String) -> EndpointResponse<EmptyResponse> {
        var params = self.paramsWithCredentials
        params["card_number"] = card
        UserDefaults[string: "abankUserCard"] = card
        
        let signatureSeed = "\(self.paramsString)\(card)"
		params.insertSignature(generatedFrom: signatureSeed)
        
        return self.create(endpoint: Self.varifyCard, parameters: params)
    }

	func register(phone: String) -> EndpointResponse<EmptyResponse> {
#if TINKOFF
		return (
			promise: Promise{ seal in seal.fulfill(EmptyResponse()) },
			cancellation: {}
		)
#else
		var params = self.paramsWithCredentials
		params["phone"] = phone

		let signatureSeed = "\(self.paramsString)\(phone)"
		params.insertSignature(generatedFrom: signatureSeed)

		return self.create(endpoint: Self.registerEndpoint, parameters: params)
#endif
	}

    func callBack(to phone: String) -> EndpointResponse<EmptyResponse> {
        var params = self.paramsWithCredentials
        params["phone"] = phone
        let signatureSeed = "\(self.paramsString)\(phone)"
		params.insertSignature(generatedFrom: signatureSeed)
        return self.create(endpoint: Self.callBack, parameters: params)
    }

    func check(phone: String) -> EndpointResponse<EmptyResponse> {
        var params = self.paramsWithCredentials
        params["phone"] = phone
        let signatureSeed = "\(self.paramsString)\(phone)"
		params.insertSignature(generatedFrom: signatureSeed)
        return self.create(endpoint: Self.checkPhone, parameters: params)
    }

	func register(card: String, surname: String, name: String, phone: String, email: String) -> EndpointResponse<EmptyResponse> {
		var params = self.paramsWithCredentials
		params["card_number"] = card
		params["phone"] = phone
		params["first_name"] = name
		params["last_name"] = surname
		params["email"] = email
		params["birthday"] = ""
		params["middle_name"] = ""

		let signatureSeed = "\(self.paramsString)\(card)\(name)\(surname)\(phone)\(email)"
		params.insertSignature(generatedFrom: signatureSeed)

		return self.create(endpoint: Self.registerProfile, parameters: params)
	}
}

struct EmptyResponse: Decodable { }

struct LogoutResponse: Decodable {
	let result: String?
	let message: String?
}
