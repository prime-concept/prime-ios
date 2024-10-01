import Alamofire
import Foundation
import PromiseKit

struct ActiveFeedback: Codable {
    struct Value: Codable {
        // "Очень сожалеем."
        let name: String?

        // "Что именно Вам не понравилось?"
        let description: String?

        // ["1", "2", "3"]
        let value: [String]? // swiftlint:disable:this discouraged_optional_collection

        // ["Несоответствие запросу", "Вариативность информации", "Скорость ответа", "Общение", "Цена"]
        let select: [String]? // swiftlint:disable:this discouraged_optional_collection
    }

    let guid: String?
    let objectId: String?
    let sourceId: String?
    let ratingSource: String?
    let ratingType: String?
    let ratingValueSelectList: [Self.Value]

    // 2022-12-27 16:57:23
    let createdAt: String?
    let showOnTask: Bool?

    var taskType: TaskType?
    var taskTitle: String?
    var taskSubtitle: String?
}

struct UserFeedback: Codable {
    let comment: String?
    let rating: String?
    let selectValues: [String]? // swiftlint:disable:this discouraged_optional_collection
}

protocol FeedbackEndpointProtocol {
    func retrieveActive() -> EndpointResponse<[ActiveFeedback]>
    func submit(new feedback: UserFeedback, guid: String) -> EndpointResponse<UserFeedback>
}

final class FeedbackEndpoint: PrimeEndpoint, FeedbackEndpointProtocol {
    // Оставляем shared, это безопасно, тк тут нет стейта
    static let shared = FeedbackEndpoint()

    override var notifiesServiceUnreachable: Bool {
        false
    }

    func retrieveActive() -> EndpointResponse<[ActiveFeedback]> {
        self.retrieve(
            endpoint: "/api/feedback/active?locale=\(Locale.primeLanguageCode)",
            parameters: ["customerId": (LocalAuthService.shared.user?.username ?? "")]
        )
    }

    func submit(new feedback: UserFeedback, guid: String) -> EndpointResponse<UserFeedback> {
        guard let dict = feedback.paramsDict else {
            return Promise<UserFeedback>
                .rejectedResponse("Trying to submit invalid feedback: \(feedback.jsonString()^)")
        }

        return self.create(
            endpoint: "/api/feedback/external/\(guid)",
            parameters: dict,
            encoding: JSONEncoding.default
        )
    }
}
