import Foundation

struct SanitizedPhoneNumber {
    let number: String

    init?(from raw: String) {
        let candidate = String(raw.filter { Int(String($0)) != nil })

        if candidate.isEmpty {
            return nil
        }

        number = candidate
    }
}
