import Foundation

enum TaskCreationFormType: String, Codable {
    case combobox = "COMBOBOX"
    case text = "TEXT"
    case airport = "AIRPORT"
    case dateTime = "DATE_TIME"
    case separator = "SEPARATOR"
    case numberText = "NUMBER_TEXT"
    case textWithoutLabel = "TEXT_WITHOUT_LABEL"
    case checkBoxLineLabel = "CHECK_BOX_LINE_LABEL"
    case partner = "PARTNER"
    case date = "DATE"
    case dictionary = "DICTIONARY"
    case dictionaryManyToMany = "DICTIONARY_MULTIPLE_CHOICE_MANY_TO_MANY2"
    case city = "CITY"
    case textArea = "TEXT_AREA"
    case dateTimeZone = "DATE_TIME_ZONE"
	case fieldNotice = "FIELD_NOTICE"
    case childAges = "CHILD_AGES"
}
