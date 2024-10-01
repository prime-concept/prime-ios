import Foundation
import ChatSDK

// FIXME:- It's CHATSDK entity, maybe import from sdk
struct Message: Decodable, Equatable {
    let guid: String
    let clientId: String
    let channelId: String
    let source: String
    let timestamp: Date
    let status: MessageStatus
    let type: MessageType
    let content: String
	let displayName: String
	private(set) var messenger: String?

	enum CodingKeys: String, CodingKey {
		case guid
		case clientId
		case channelId
		case source
		case timestamp
		case status
		case type
		case content
		case meta
	}

	private static let timestampFormatter = with(DateFormatter()) {
		$0.dateFormat = "EEE MMM dd HH:mm:ss yyyy"
		$0.timeZone = TimeZone(abbreviation: "MSK")
		$0.locale = Locale(identifier: "en_US_POSIX")
	}

	init(
		guid: String,
		clientId: String,
		channelId: String,
		source: String,
		timestamp: Date,
		status: MessageStatus,
		type: MessageType,
		content: String,
		displayName: String = "",
		messenger: String? = nil
	) {
		self.guid = guid
		self.clientId = clientId
		self.channelId = channelId
		self.source = source
		self.timestamp = timestamp
		self.status = status
		self.type = type
		self.content = content
		self.displayName = displayName
		self.messenger = messenger
	}

	init(from decoder: Decoder) throws {
		do {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.guid = try container.decodeIfPresent(String.self, forKey: .guid) ?? ""
			self.clientId = try container.decodeIfPresent(String.self, forKey: .clientId) ?? ""
			self.channelId = try container.decodeIfPresent(String.self, forKey: .channelId) ?? ""
			self.source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""

			let zeroDate = Date(timeIntervalSince1970: 0)
			let timestampString = try? container.decodeIfPresent(String.self, forKey: .timestamp)
			var timestamp = zeroDate

			if let timestampString = timestampString {
				let zonelessString = timestampString.replacing(regex: "(?<=:\\d{2})\\s*\\w{3}\\s*(?=\\d{4}$)", with: " ")
				let maybeDate = Self.timestampFormatter.date(from: zonelessString)
				if maybeDate == nil {
					let message = "1) TASK LAST MESSAGE PARSING FAILED maybeDate = NULL, timestampString = \(timestampString), zonelessString = \(zonelessString)"
					AnalyticsReportingService
						.shared.log(
							name: "[ERROR] \(Swift.type(of: self)) parsing failed \(message)"
						)
					DebugUtils.shared.log(message)
				}
				timestamp = maybeDate?.to(timezone: Calendar.current.timeZone) ?? zeroDate
			} else {
				let message = "2) TASK LAST MESSAGE PARSING FAILED timestampString = NULL"

				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) parsing failed \(message)"
					)

				DebugUtils.shared.log(message)
			}

			self.timestamp = timestamp

			//swiftlint:disable force_unwrapping
			self.status = try container.decodeIfPresent(MessageStatus.self, forKey: .status)!
			self.type = try container.decodeIfPresent(MessageType.self, forKey: .type)!
			//swiftlint:enable force_unwrapping
			self.content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
			let meta = try container.decodeIfPresent([String: Any].self, forKey: .meta) ?? [:]
			self.displayName = (meta["document_name"] as? String) ?? (meta["contact_name"] as? String) ?? ""
		} catch {
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) parsing failed",
					parameters: error.asDictionary
				)
			DebugUtils.shared.log("3) TASK LAST MESSAGE PARSING FAILED: \(error)")
			throw error
		}
	}
}
