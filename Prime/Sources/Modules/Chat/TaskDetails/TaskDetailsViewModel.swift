import Foundation
import UIKit

struct TaskDetailsViewModel {

    enum Constants {
        static let excludingFields: [String] = ["worldwide"]
    }

    struct Section {
        struct Row {
            init(name: String, value: String, action: (() -> Void)? = nil) {
                self.name = name
                self.value = value
                self.action = action
            }

            let name: String
            let value: String
            let action: (() -> Void)?
        }
        let address: String?
        let taskNumber: String?
        let title: String?
        let subtitle: String?
        let haveToShowMap: Bool?
        let longitude: Double?
        let latitude: Double?
        let showSeparator: Bool
        let rows: [Row]
    }

    struct Button {
        let title: String
        let action: () -> Void
    }

    let title: String
    let sections: [Section]
    let button: Button?

    init(title: String, sections: [Self.Section], button: Self.Button?) {
        self.title = title
        self.sections = sections
        self.button = button
    }

    init(task: Task, urlHandler: @escaping ((URL) -> Void)) {
        var sections = [Self.Section]()

        if !task.details.isEmpty {
            var details = Self.geoAwareDetails(from: task.details)
            if task.reserved {
                details.append(
                    .init(
                        name: "task.hasReservation.verbose".localized,
                        value: "task.hasReservation.yes".localized
                    )
                )
            }

            sections.append(Self.makeSectionForTask(taskNumber: task.taskID))

            sections.append(.init(
                address: nil,
                taskNumber: nil,
                title: "",
                subtitle: nil,
                haveToShowMap: false,
                longitude: nil,
                latitude: nil,
                showSeparator: false,
                rows: details.compactMap { detail in
                    guard
                        let name = detail.name,
                        var value = detail.value,
                        !Constants.excludingFields.contains(value.lowercased())
                    else {
                        return nil
                    }

                    var action: (() -> Void)?
                    if
                        let url = detail.url ?? URL(string: Self.updateToken(in: value)),
                        url.scheme^.hasPrefix("http")
                    {
                        action = {
                            urlHandler(url)
                        }
                        value = Self.stripToken(form: value)
                    }

                    return Self.Section.Row(
                        name: name,
                        value: value,
                        action: action
                    )
                }
            ))
        }
        
        if task.hasCoordinates, let long = task.longitude, let lat = task.latitude {
            sections.append(
                Self.makeSectionForMap(
                    long: long,
                    lat: lat,
                    address: task.address,
                    showSeparator: task.ordersWaitingForPayment.first != nil
                )
            )
        }

        var button: Self.Button?

        if let order = task.ordersWaitingForPayment.first {
            var rows: [Self.Section.Row] = [
                .init(name: "task.detail.order".localized, value: "№\(order.id)"),
                .init(name: "task.detail.amount".localized, value: order.amount + " " + order.currency),
                .init(name: "task.detail.dueDate".localized, value: order.dueDate)
            ]

            let status: String? = {
                switch order.status {
                case .created:
                    return "task.detail.created".localized
                case .requiresPayment:
                    return "task.detail.status.requiresPayment".localized
                case .partiallyPaid:
                    return "task.detail.status.partiallyPaid".localized
                case .paid:
                    return "task.detail.status.paid".localized
                case .canceled:
                    return "task.detail.status.cancel".localized
                case .hold:
                    return "task.detail.status.onHold".localized
                default:
                    return nil
                }
            }()

            status.some {
                rows.append(.init(name: "Статус", value: $0))
            }

            sections.append(
                .init(
                    address: nil,
                    taskNumber: nil,
                    title: "task.detail.payment".localized,
                    subtitle: nil,
                    haveToShowMap: false,
                    longitude: nil,
                    latitude: nil,
                    showSeparator: false,
                    rows: rows
                )
            )

            button = .init(title: "tasksList.pay".localized) {
                NotificationCenter.default.post(
                    name: .orderPaymentRequested,
                    object: nil,
                    userInfo: ["order": order]
                )
            }
        }

        self.init(title: task.title^, sections: sections, button: button)
    }
    
    private static func makeSectionForMap(long: Double, lat: Double, address: String?, showSeparator: Bool) -> Section {
        return .init(
            address: address,
            taskNumber: nil,
            title: "",
            subtitle: nil,
            haveToShowMap: true,
            longitude: long,
            latitude: lat,
            showSeparator: showSeparator,
            rows: []
        )
    }
    
    private static func makeSectionForTask(taskNumber: Int?) -> Section {
        let taskNumberString = taskNumber != nil ? ("task.detail.title".localized + " (№\(taskNumber!))") : nil
        return .init(
            address: nil,
            taskNumber: taskNumberString,
            title: "",
            subtitle: nil,
            haveToShowMap: false,
            longitude: nil,
            latitude: nil,
            showSeparator: false,
            rows: []
        )
    }

    /**
     Flattens pairs of geo-related details into a single detail
     {
         "name" : "Россия, Москва\nул. Маршала Катукова, 23",
         "value" : "https:\/\/www.google.ru\/maps\/search\..."
     },
     {
         "value" : "Россия, Москва, ул. Маршала Катукова, 23",
         "latitude" : 55.805682,
         "name" : "Чайхона №1 в Строгино",
         "longitude" : 37.413271
     }
     ------>
     {
         "name" : "Россия, Москва\nул. Маршала Катукова, 23",
         "value" : "Чайхона №1 в Строгино",
         "url" : "https:\/\/www.google.ru\/maps\/search\..."
     },
     */
    private static func geoAwareDetails(from details: [TaskDetail]) -> [TaskDetail] {
        var setOfIndicesToRemove = Set<Int>()

        var geoAwareDetails = details

        for i in 0..<details.count {
            var detail = details[i]

            guard detail.hasMeaningfulCoordinates else {
                continue
            }

            for indexToDelete in 0..<details.count {
                let detailWithLink = details[indexToDelete]
                let name = detailWithLink.name^.stripping(regex: "[^A-Za-z0-9_]")
                let value = detail.value^.stripping(regex: "[^A-Za-z0-9_]")

                guard name == value else { continue }
                guard let value = detailWithLink.value else { break }

                let url = URL(string: Self.updateToken(in: value))

                guard let url, UIApplication.shared.canOpenURL(url) else {
                    break
                }

                detail.name = "task.detail.location.name".localized
                detail.url = url

                setOfIndicesToRemove.insert(indexToDelete)

                break
            }

            geoAwareDetails[i] = detail
        }

        let arrayOfIndicesToRemove = [Int](setOfIndicesToRemove).sorted(by: >)
        for index in arrayOfIndicesToRemove {
            geoAwareDetails.remove(at: index)
        }

        return geoAwareDetails
    }

    private static func updateToken(in string: String) -> String {
        guard let token = LocalAuthService.shared.token?.accessToken else {
            return string
        }

        let result = string.replacingOccurrences(
            of: "\\?access_token=.+?(?=&|$)",
            with: "?access_token=\(token)",
            options: .regularExpression
        )

        return result
    }
    
    private static func stripToken(form string: String) -> String {
        let result = string.replacingOccurrences(
            of: "\\?access_token=.+?(?=&|$)",
            with: "",
            options: .regularExpression
        )

        return result
    }
}

extension TaskDetailsViewModel {
    var sample: TaskDetailsViewModel {
        TaskDetailsViewModel(
            title: "ТЕСТ",
            sections: [.init(address: "", taskNumber: nil, title: "Заголовок", subtitle: "Значение", haveToShowMap: false, longitude: nil, latitude: nil, showSeparator: false, rows: [
                .init(name: "URL", value: "https://www.yandex.ru?query=self&actionButton=setTitle"),
                .init(name: "Phone", value: "+7 (900) 000-00-05"),
                .init(name: "Address", value: "Россия, г. Москва, ул. Шарикоподшипниковская, д. 25"),
                .init(name: "Время", value: "Завтра, 19:45"),
                .init(name: "Мультилайн", value: "In the next part, we’ll try to complicate things a bit and see how to manage situations where the maximum size of textView also needs to be dynamic, for example on smaller screens when we display the on-screen keyboard.")
            ])],
            button: nil
        )
    }
}
