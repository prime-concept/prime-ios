import Foundation

struct TaskCreationFormResponse: Codable {
    struct TaskTypeFormContainer: Codable {
        let taskTypeForm: TaskTypeForm
    }

    let data: TaskTypeFormContainer
}

struct TaskTypeForm: Codable {
    let field: [TaskCreationForm]

    enum CodingKeys: String, CodingKey {
        case field
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let fields = try container.decode([TaskCreationForm?].self, forKey: .field)
            self.field = fields.compactMap { $0 }
        } catch {
            throw error
        }
    }
}

struct TaskCreationForm: Codable {
    let allowBlank: Bool
    let defaultValue: String?
    let hidden: Bool
    let label: String
    let name: String
    let readOnly: Bool
    var typeString: String
    let type: TaskCreationFormType?
    let visibility: [Int]
    let options: [TaskCreationFieldOptions]
	let partnerTypeId: [Int]

    enum CodingKeys: String, CodingKey {
        case allowBlank
        case defaultValue
        case hidden
        case label
        case name
        case readOnly
        case typeString = "type"
        case visibility
        case options
		case partnerTypeId
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.allowBlank = try container.decode(Bool.self, forKey: .allowBlank)
            self.hidden = try container.decode(Bool.self, forKey: .hidden)
            self.label = try container.decode(String.self, forKey: .label)
            self.name = try container.decode(String.self, forKey: .name)
            self.readOnly = try container.decode(Bool.self, forKey: .readOnly)
            self.typeString = try container.decode(String.self, forKey: .typeString)
            self.type = TaskCreationFormType(rawValue: self.typeString)
            self.visibility = try container.decodeIfPresent([Int].self, forKey: .visibility) ?? []
            self.options = try container.decodeIfPresent(
                [TaskCreationFieldOptions].self,
                forKey: .options
            ) ?? []

            let defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue)
            if defaultValue == nil, self.type == .checkBoxLineLabel {
                self.defaultValue = "0"
            } else {
                self.defaultValue = defaultValue
            }
			self.partnerTypeId = try container.decodeIfPresent([Int].self, forKey: .partnerTypeId) ?? []
        } catch {
            throw error
        }
    }
}

struct TaskCreationFieldOptions: Codable {
    let name: String
    let value: String
    let visibilityClear: Int
    let visibilitySet: Int
}
