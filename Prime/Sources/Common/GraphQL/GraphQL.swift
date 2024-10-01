import Foundation

struct GraphQL {
    struct Request: Encodable {
        var query: String
        var variables: [String: AnyEncodable]
    }

    struct Response<Model: Decodable>: Decodable {
        var data: Model
    }

    struct ServerError: Decodable {
        var errors: [Error]
    }

    struct Error: Swift.Error, Decodable {
        var message: String
    }
}

struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}

extension Decodable {
	//swiftling:disable all
	static var FAILED_DECODING_ENTITY_ID: Int {
		Int.min
	}
	//swiftling:enable all
}
