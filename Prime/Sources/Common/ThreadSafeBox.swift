import Foundation

@propertyWrapper
class ThreadSafe<ValueType> {
    private let isolationQueue = DispatchQueue(
        label: "ThreadSafeBox_\(ValueType.self)_\(UUID().uuidString)",
        attributes: .concurrent
    )
    private var value: ValueType
    
    init(wrappedValue: ValueType) {
        self.value = wrappedValue
    }
    
    var wrappedValue: ValueType {
        get {
            isolationQueue.sync {
                return value
            }
        } set {
            isolationQueue.async(flags: .barrier) {
                self.value = newValue
            }
        }
    }
}
