import Foundation

enum ContentType {
	case image
	case text
	case pdf
	case json
	case xml
	case audio
	case video
	case binary
	case animation
	case unknown

	init(rawValue: String) {
		let lowercasedValue = rawValue.lowercased()

		if lowercasedValue == "image/gif" {
			self = .animation
		} else if lowercasedValue.hasPrefix("image/") {
			self = .image
		} else if lowercasedValue.hasPrefix("text/") {
			self = .text
		} else if lowercasedValue == "application/pdf" {
			self = .pdf
		} else if lowercasedValue == "application/json" {
			self = .json
		} else if lowercasedValue == "application/xml" || lowercasedValue == "text/xml" {
			self = .xml
		} else if lowercasedValue.hasPrefix("audio/") {
			self = .audio
		} else if lowercasedValue.hasPrefix("video/") {
			self = .video
		} else if lowercasedValue.hasPrefix("application/") {
			self = .binary
		} else {
			self = .unknown
		}
	}
}
