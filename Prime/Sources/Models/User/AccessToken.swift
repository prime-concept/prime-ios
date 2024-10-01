import Foundation

final class AccessToken: Codable, Equatable {
	internal init(
        accessToken: String,
        refreshToken: String,
        tokenType: String = "bearer",
        expiresIn: Int,
        scope: String = "private"
    ) {
		self.accessToken = accessToken
		self.tokenType = tokenType
		self.refreshToken = refreshToken
		self.expiresIn = expiresIn
		self.scope = scope
	}
	
	var accessToken: String
    var tokenType: String
	var refreshToken: String?
    var expiresIn: Int
    var scope: String?

	var isValid: Bool {
		!self.accessToken.isEmpty
	}

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope = "scope"
    }

    init(from decoder: Decoder) {
        let container = try? decoder.container(keyedBy: CodingKeys.self)

        self.accessToken = (try? container?.decode(String.self, forKey: .accessToken)) ?? ""
        self.tokenType = (try? container?.decode(String.self, forKey: .tokenType)) ?? ""
        self.refreshToken = (try? container?.decode(String.self, forKey: .refreshToken))
		self.expiresIn = (try? container?.decode(Int.self, forKey: .expiresIn)) ?? Int.max
        self.scope = (try? container?.decode(String.self, forKey: .scope))
    }

	static func == (lhs: AccessToken, rhs: AccessToken) -> Bool {
		lhs.accessToken == rhs.accessToken
	}
}

extension AccessToken {
	static let empty = AccessToken(accessToken: "", refreshToken: "", expiresIn: 0)
}
