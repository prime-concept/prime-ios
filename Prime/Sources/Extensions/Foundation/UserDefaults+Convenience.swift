import Foundation

extension UserDefaults {
	static let groupShared = UserDefaults(suiteName: Config.sharingGroupName)!
	
	static subscript(string key: String) -> String? {
		get {
			UserDefaults.standard.string(forKey: key)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: key)
		}
	}

	static subscript(int key: String) -> Int {
		get {
			UserDefaults.standard.integer(forKey: key)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: key)
		}
	}

	static subscript(bool key: String) -> Bool {
		get {
			UserDefaults.standard.bool(forKey: key)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: key)
		}
	}

	static subscript(float key: String) -> Float? {
		get {
			if UserDefaults.standard.value(forKey: key) == nil {
				return nil
			}
			
			return UserDefaults.standard.float(forKey: key)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: key)
		}
	}

	static subscript(double key: String) -> Double? {
		get {
			if UserDefaults.standard.value(forKey: key) == nil {
				return nil
			}

			return UserDefaults.standard.double(forKey: key)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: key)
		}
	}

	static func has(key: String) -> Bool {
		UserDefaults.standard.object(forKey: key) != nil
	}
}
