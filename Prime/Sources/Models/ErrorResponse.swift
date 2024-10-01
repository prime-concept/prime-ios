import Foundation

struct ErrorResponse: Decodable {
    let error: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case error
        case description = "error_description"
        case errorDescription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.error = try container.decode(String.self, forKey: .error)

        if let description = try? container.decodeIfPresent(String.self, forKey: .errorDescription) {
            self.description = description
        } else if let description = try? container.decodeIfPresent(String.self, forKey: .description) {
            self.description = description
        } else {
            self.description = ""
        }
    }
}
