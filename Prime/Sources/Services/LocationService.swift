import Foundation
import CoreLocation

/// Return true if you want to receive more location updates, false to unsubscribe.
typealias LocationServiceFetchCompletion = (LocationServiceResult) -> Bool
typealias LocationAuthorizationStatusListener = (CLAuthorizationStatus, CLAuthorizationStatus) -> Void

enum LocationServiceResult {
    case success(CLLocationCoordinate2D)
    case error(LocationServiceError)
}

enum LocationServiceError: Error {
    case notAllowed
    case restricted
    case systemError(Error)
}

protocol LocationServiceProtocol: AnyObject {
    /// Last fetched location
    var lastLocation: CLLocation? { get }

	var latestAuthorizationStatus: CLAuthorizationStatus { get }

    /// Get current location of the device
	/// If completion returns false, it will be removed and will receive no further locations
	/// If true - it will be kept for continuous listening.
    func fetchLocation(completion: @escaping LocationServiceFetchCompletion)

	func addAuthorizationStatusListener(_ listener: @escaping LocationAuthorizationStatusListener)

    /// Continuously get current location of the device
    func startGettingLocation(completion: @escaping LocationServiceFetchCompletion)

    /// Stop getting location of the device.
    /// Should be used after calling `startGettingLocation(completion:)`
    func stopGettingLocation()

    /// Distance in meters from the last fetched location
    func distanceFromLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance?

    /// Reverse geocoding for coordinate
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Swift.Error>) -> Void)
}

final class LocationService: CLLocationManager, LocationServiceProtocol {
    enum Settings {
        static let accuracy = kCLLocationAccuracyBest
        static let distanceFilter: CLLocationDistance = 50
    }

	// Оставляем shared, это безопасно, тк тут нет данных специфичных для сессии пользователя
	static let shared = LocationService()

    private var fetchCompletions = [LocationServiceFetchCompletion]()
	private var authorizationStatusListeners = [LocationAuthorizationStatusListener]()

    private lazy var geocoder = CLGeocoder()
    private static let geocodingQueue = DispatchQueue(label: "LocationService.geocoding")
    private let geocodingSemaphore = DispatchSemaphore(value: 1)

    private(set) var lastLocation: CLLocation?
	private(set) var latestAuthorizationStatus: CLAuthorizationStatus

    override init() {
		self.latestAuthorizationStatus = Self.authorizationStatus()
		
        super.init()

        self.desiredAccuracy = Settings.accuracy
        self.distanceFilter = Settings.distanceFilter
        self.delegate = self
    }

	private var forcedLocation: CLLocation? {
		guard let latitude = UserDefaults[double: "TECHNOLAB_FORCED_LOCATION_LATITUDE"],
			  let longitude = UserDefaults[double: "TECHNOLAB_FORCED_LOCATION_LONGITUDE"] else {
			return nil
		}
		return CLLocation(latitude: latitude, longitude: longitude)
	}

    func fetchLocation(completion: @escaping LocationServiceFetchCompletion) {
		self.fetchCompletions.append(completion)
        self.requestWhenInUseAuthorization()
        self.startUpdatingLocation()
    }

    func startGettingLocation(completion: @escaping LocationServiceFetchCompletion) {
		self.fetchCompletions.append(completion)

        self.requestAlwaysAuthorization()
        self.startUpdatingLocation()
    }

    func stopGettingLocation() {
        self.stopUpdatingLocation()
    }

    func distanceFromLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return self.lastLocation?.distance(from: location)
    }

    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Swift.Error>) -> Void) {
        Self.geocodingQueue.async {
            self.geocodingSemaphore.wait()

            self.geocoder.reverseGeocodeLocation(location) { (placemark, error) in
                defer {
                    self.geocodingSemaphore.signal()
                }

                if let error = error {
                    return completion(.failure(error))
                }

                let name = placemark?.first?.name
                let city = placemark?.first?.locality
                let country = placemark?.first?.country
                let address = [name, city, country].compactMap({ $0 }).joined(separator: ", ")

                guard !address.isEmpty else {
					return completion(.failure(Endpoint.Error(.decodeFailed, details: "Invalid placemark")))
                }

                completion(.success(address))
            }
        }
    }

	func addAuthorizationStatusListener(_ listener: @escaping LocationAuthorizationStatusListener) {
		self.authorizationStatusListeners.append(listener)
	}

    // MARK: - Private

    private func update(with result: LocationServiceResult) {
		self.fetchCompletions = self.fetchCompletions.filter { completion in
			completion(result)
		}
		if self.fetchCompletions.isEmpty {
			self.stopUpdatingLocation()
		}
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		var location = locations.last
		
		if let forcedLocation = self.forcedLocation {
			location = forcedLocation
		}

        guard let location else {
            return
        }

        self.lastLocation = location
        self.update(with: .success(location.coordinate))
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		self.authorizationStatusListeners.forEach {
			$0(self.latestAuthorizationStatus, status)
		}

		self.latestAuthorizationStatus = status

        switch status {
        case .restricted:
            self.update(with: .error(.restricted))
        case .denied:
            self.update(with: .error(.notAllowed))
        // Debug only cases
        case .notDetermined:
            DebugUtils.shared.alert(sender: self, "location status not determined")
        case .authorizedAlways, .authorizedWhenInUse:
			DebugUtils.shared.log(sender: self, "location status is OK")
			if !self.fetchCompletions.isEmpty {
				self.fetchLocation(completion: { _ in false }) // Empty completion just to call the method
			}
        @unknown default:
            DebugUtils.shared.alert(sender: self, "unknown authorization status \(status)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        switch error._code {
        case 1:
            self.update(with: .error(.notAllowed))
        default:
            self.update(with: .error(.systemError(error)))
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
	public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		lhs.latitude == rhs.latitude &&
		lhs.longitude == rhs.longitude
	}

	var location: CLLocation {
		CLLocation(
			latitude: self.latitude,
			longitude: self.longitude
		)
	}

	var isZero: Bool {
		self.latitude == 0 && self.longitude == 0
	}
}
