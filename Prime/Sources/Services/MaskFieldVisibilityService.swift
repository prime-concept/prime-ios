import Foundation

protocol MaskFieldVisibilityServiceProtocol {
    func isFieldVisible(formVisibilityMask: Int, fieldVisibilityMask: Int?) -> Bool
    func getChangedFormVisibilityMask(formVisibilityMask: Int, visibilityClear: Int, visibilitySet: Int) -> Int
}

class MaskFieldVisibilityService: MaskFieldVisibilityServiceProtocol {
    func isFieldVisible(formVisibilityMask: Int, fieldVisibilityMask: Int?) -> Bool {
        guard let fieldVisibilityMask = fieldVisibilityMask else {
            return true
        }
        return (formVisibilityMask & fieldVisibilityMask) > 0
    }

    func getChangedFormVisibilityMask(formVisibilityMask: Int, visibilityClear: Int, visibilitySet: Int) -> Int {
        (formVisibilityMask | visibilitySet) & ~visibilityClear
    }
}
