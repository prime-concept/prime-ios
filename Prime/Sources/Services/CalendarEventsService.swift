import EventKit
import RealmSwift

protocol CalendarEventsServiceProtocol: AnyObject {
	func save(events: [CalendarEvent], completion: (() -> Void)?)
	func remove(events: [CalendarEvent], completion: (() -> Void)?)

	var onSave: ((CalendarEvent?, Swift.Error?) -> Void)? { get }
	var onRemove: ((CalendarEvent?, Swift.Error?) -> Void)? { get }

	func printEvents()
}

final class CalendarEventsService: RealmPersistenceService<CalendarEventSyncObject>, CalendarEventsServiceProtocol {
	// Оставляем shared, это безопасно, тк тут нет данных, специфичных для сессии пользователя
	static let shared = CalendarEventsService()

	@PersistentCodable(fileName: "CalendarEventsService.calendarIdentifier", async: false)
	private var calendarIdentifier: String? = nil

	var onSave: ((CalendarEvent?, Swift.Error?) -> Void)?
	var onRemove: ((CalendarEvent?, Swift.Error?) -> Void)?

	func printEvents() {
		let events: [CalendarEventSyncObject] = self.read()
		for event in events {
			print(event)
		}
	}
	
    private let eventStore = EKEventStore()
	private lazy var eventCalendar: EKCalendar = {
		if let calendarIdentifier = self.calendarIdentifier,
		   let calendar = self.eventStore.calendar(withIdentifier: calendarIdentifier) {
			return calendar
		}

		let calendar = EKCalendar(for: .event, eventStore: self.eventStore)
		calendar.title = Bundle.main.appName
		calendar.cgColor = Palette.shared.brandPrimary.rawValue.cgColor
		calendar.source = self.eventStore.defaultCalendarForNewEvents?.source
		try? self.eventStore.saveCalendar(calendar, commit: true)
		self.calendarIdentifier = calendar.calendarIdentifier
		return calendar
	}()


	private static var permissionRequestInProgress = false
	private var pendingPermissionCompletions = [EKEventStoreRequestAccessCompletionHandler]()

    // Check Calendar permissions auth status
    // Try to add an event to the calendar if authorized
	func save(events: [CalendarEvent], completion: (() -> Void)?) {
		if events.isEmpty {
			completion?()
			return
		}

		var evenIDsToSave = Set(events.map(\.id))

		let completionWithError = { [weak self] (error: Error?) in
			if let error {
				completion?()
				self?.onSave?(nil, error)
				return
			}

			events.forEach { event in
				self?.insertOrUpdate(event: event) { _ in
					evenIDsToSave.remove(event.id)
					if evenIDsToSave.isEmpty {
						completion?()
					}
				}
			}
		}

		self.requestAccess(then: completionWithError)
	}

	func remove(events: [CalendarEvent], completion: (() -> Void)?) {
		if events.isEmpty {
			completion?()
			return
		}

		var evenIDsToRemove = Set(events.map(\.id))

		let completionWithError = { [weak self] (error: Error?) in
			if let error {
				completion?()
				self?.onRemove?(nil, error)
				return
			}

			events.forEach { event in
				self?.remove(event: event) { _ in
					evenIDsToRemove.remove(event.id)
					if evenIDsToRemove.isEmpty {
						completion?()
					}
				}
			}
		}

		self.requestAccess(then: completionWithError)
	}

	private func requestAccess(
		then completionWithError: @escaping ((Error?) -> Void)
	) {
		let authStatus = self.getAuthorizationStatus()

		switch authStatus {
			case .authorized, .fullAccess, .writeOnly:
				onMain { completionWithError(nil) }
			case .notDetermined:
				//Auth is not determined
				//We should request access to the calendar
				let permissionCompletion: EKEventStoreRequestAccessCompletionHandler = { accessGranted, _ in
					guard accessGranted else {
						completionWithError(Error.calendarAccessDeniedOrRestricted)
						return
					}
					onMain { completionWithError(nil) }
				}
				
				PermissionService.shared.schedulePermissionRequest {
					self.requestAccess(completion: permissionCompletion)
				}
			case .denied, .restricted:
				// Auth denied or restricted, we should display a popup
				onMain { completionWithError(Error.calendarAccessDeniedOrRestricted) }
			@unknown default:
				let message = "Could not handle unknown EKAuthorizationStatus case: \(authStatus)"
				DebugUtils.shared.log(sender: self, message)
				assertionFailure(message)
		}
	}

    // Request access to the Calendar
    func requestAccess(completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
		self.pendingPermissionCompletions.append(completion)

		if Self.permissionRequestInProgress {
			return
		}

		Self.permissionRequestInProgress = true

        self.eventStore.requestAccess(to: .event) { [weak self] (accessGranted, error) in
			self?.pendingPermissionCompletions.forEach { completion in
				completion(accessGranted, error)
			}

			self?.pendingPermissionCompletions.removeAll()
			Self.permissionRequestInProgress = false
        }
    }

    // Get Calendar auth status
    private func getAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: EKEntityType.event)
    }

    // Generate an event which will be then added to the calendar
    private func generateEKEvent(from event: CalendarEvent) -> EKEvent {
        let newEvent = EKEvent(eventStore: self.eventStore)
		newEvent.calendar = self.eventCalendar
		newEvent.title = event.title
		newEvent.location = event.location ?? event.task?.address ?? ""
		newEvent.startDate = event.startDateDate
		newEvent.endDate = event.startDateDate

        return newEvent
    }

    // Try to save an event to the calendar
	private func insertOrUpdate(event: CalendarEvent, completion: ((Swift.Error?) -> Void)?) {
        // Update existing event of event in iOS Calendar App
		if let eventInCalendar = self.loadEKEvent(with: event.id) {
			onMain {
				do {
					try self.update(eventInCalendar, with: event)
					completion?(nil)
					self.onSave?(event, nil)
				} catch {
					AnalyticsReportingService
						.shared.log(
							name: "[ERROR] \(Swift.type(of: self)) update(eventInCalendar, with: event) failed",
							parameters: error.asDictionary
						)
					completion?(error)
					self.onSave?(nil, error)
				}
			}
			return
        }

		// Add new event to iOS Calendar App
		onMain {
			do {
				let eventToAdd = self.generateEKEvent(from: event)
				try self.eventStore.save(eventToAdd, span: .thisEvent)

				onGlobal {
					let eventToCache = CalendarEventSyncObject(
						id: event.id,
						eventID: eventToAdd.eventIdentifier
					)

					self.write(object: eventToCache)

					onMain {
						completion?(nil)
						self.onSave?(event, nil)
					}
				}
			} catch {
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) save .thisEvent failed",
						parameters: error.asDictionary
					)

				completion?(error)
				self.onSave?(nil, Error.eventNotAddedToCalendar)
			}
		}
    }

	private func remove(event: CalendarEvent, completion: ((Swift.Error?) -> Void)?) {
		// Update existing event of event in iOS Calendar App
		guard let eventInCalendar = self.loadEKEvent(with: event.id) else {
			completion?(nil)
			return
		}

		onMain {
			do {
				try self.eventStore.remove(eventInCalendar, span: .thisEvent, commit: true)
				completion?(nil)
				self.onRemove?(event, nil)
			} catch {
				completion?(error)
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) remove(eventInCalendar, with: event) failed",
						parameters: error.asDictionary
					)
				self.onRemove?(nil, error)
			}
		}
	}

    // Check if the event was already added to the calendar
    private func loadEKEvent(with id: Int) -> EKEvent? {
		let cachedEvent = self.read().first{ $0.id == id }
        guard let cachedEventID = cachedEvent?.eventID else {
            return nil
        }
        return self.eventStore.event(withIdentifier: cachedEventID)
    }

	// Check if the event was already added to the calendar
	private func loadEKEvent(cachedEvent eventID: String) -> EKEvent? {
		return self.eventStore.event(withIdentifier: eventID)
	}

	private func update(_ ekEvent: EKEvent, with event: CalendarEvent) throws {
        do {
			ekEvent.title = event.title
			ekEvent.startDate = event.startDateDate
			ekEvent.endDate = event.endDateDate
            try self.eventStore.save(ekEvent, span: .thisEvent)
        } catch {
            // Error while trying to update event in calendar
            throw(Error.eventCouldNotBeUpdated)
        }
    }

    // MARK: - Enums

    enum Error: Swift.Error {
        case eventNotAddedToCalendar
        case eventAlreadyExistsInCalendar
        case calendarAccessDeniedOrRestricted
        case eventCouldNotBeUpdated
    }
}

extension CalendarEventsService {
	func clearIOSCalendar(completion: (() -> Void)? = nil) {
		self.requestAccess { _,  _ in
			onMain {
				try? self.eventStore.removeCalendar(self.eventCalendar, commit: true)
				self.deleteAll()
				completion?()
			}
		}
	}
}

struct CalendarEventSyncObject {
    let id: Int
    let eventID: String
}

extension CalendarEventSyncObject: RealmObjectConvertible {
    typealias RealmObjectType = CalendarEventSyncPersistent

    init(realmObject: CalendarEventSyncPersistent) {
        self = CalendarEventSyncObject(
			id: realmObject.id,
            eventID: realmObject.eventID
        )
    }

    var realmObject: CalendarEventSyncPersistent { CalendarEventSyncPersistent(plainObject: self) }
}

final class CalendarEventSyncPersistent: Object {
	@objc dynamic var id: Int = 0
    @objc dynamic var eventID: String = ""

    override class func primaryKey() -> String? { "id" }
}

extension CalendarEventSyncPersistent {
    convenience init(plainObject: CalendarEventSyncObject) {
        self.init()
        self.id = plainObject.id
        self.eventID = plainObject.eventID
    }
}
