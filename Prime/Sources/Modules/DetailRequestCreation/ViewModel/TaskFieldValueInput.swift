import Foundation

protocol TaskFieldValueInputProtocol {
    func setup(with viewModel: TaskCreationFieldViewModel)
}

class TaskFieldValueInput: Codable {
    var dblValue: Float?
    var dictionaryOptions: [String] = []
    var dtValue: String?
    var fieldName: String
    var intValue: Int?
    var newValue: String = ""
    var oldValue: String?
    var printableValue: String?
    var timezoneOffset: Int?

    init(form: TaskCreationForm) {
        self.fieldName = form.name
    }
}

class TaskCreationFieldViewModel {
    var form: TaskCreationForm
    var input: TaskFieldValueInput
    var isVisible: Bool = false

    var onValidate: ((Bool, String?) -> Void)?

    var title: String {
        form.label + (form.allowBlank ? "" : "*")
    }

    init(form: TaskCreationForm, input: TaskFieldValueInput, isVisible: Bool = false) {
        self.form = form
        self.input = input
        if let defaultValue = self.form.defaultValue {
            self.input.dictionaryOptions = [defaultValue]
        }
        self.isVisible = isVisible
    }
}
