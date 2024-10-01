import Foundation

extension Swift.Error {
	var isChangedPinToken: Bool {
		if self.code == 400 {
			return self.descriptionLowercased.contains("bad credentials")
		}

		if self.code == 401 {
			return self.descriptionLowercased.contains("password update")
		}

		return false
	}

	var isExpiredToken: Bool {
		if self.code == 401 {
			return self.descriptionLowercased.contains("invalid access token")
		}
		return false
	}

	var isDeletedUserToken: Bool {
		if self.code == 401 {
			return self.descriptionLowercased.contains("unable to find user by refresh token")
		}
		return false
	}

	var isNoRefreshToken: Bool {
		if self.code == 499 {
			return self.descriptionLowercased == "NO_REFRESH_TOKEN"
		}
		return false
	}

	var descriptionLowercased: String {
		(self as NSError).description.lowercased()
	}

	var code: Int {
		(self as NSError).code
	}
}
