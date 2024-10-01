import UIKit

private final class AssociatedProxyTable<KeyType: AnyObject, ValueType: AnyObject> {
    private let key: UnsafeRawPointer

    init(key: UnsafeRawPointer) {
        self.key = key
    }

    subscript(holder: KeyType) -> ValueType? {
        get {
            objc_getAssociatedObject(holder, self.key) as? ValueType
        }
        set {
            objc_setAssociatedObject(holder, self.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIControl {
    func setEventHandler(for controlEvents: UIControl.Event, action: (() -> Void)?) {
        let handlers = Storage.table[self] ?? NSMutableDictionary()

        if let currentHandler = handlers[controlEvents.rawValue] {
            self.removeTarget(currentHandler, action: #selector(Handler.invoke), for: controlEvents)
            handlers[controlEvents.rawValue] = nil
        }

        if let newAction = action {
            let newHandler = Handler(action: newAction)
            // swiftlint:disable:next addtarget_vs_closures
            self.addTarget(newHandler, action: #selector(Handler.invoke), for: controlEvents)
            handlers[controlEvents.rawValue] = newHandler
        }

        Storage.table[self] = handlers
    }

    private final class Handler: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc
        func invoke() {
            action()
        }
    }

    private struct Storage {
        private static var key = 0

        static let table = AssociatedProxyTable<UIControl, NSMutableDictionary>(key: &Self.key)
    }
}

extension UIView {
    @discardableResult
    func addGestureRecognizer<GestureType: UIGestureRecognizer>(
        action: @escaping (GestureType) -> Void
    ) -> GestureType {
        let handler = Handler<GestureType>(action: action)
        let gesture = GestureType(target: handler, action: #selector(Handler.invoke(gesture:)))
        Storage.table[gesture] = handler

        self.addGestureRecognizer(gesture)
        return gesture
    }

    private final class Handler<GestureType: UIGestureRecognizer>: NSObject {
        private let action: (GestureType) -> Void

        init(action: @escaping (GestureType) -> Void) {
            self.action = action
        }

        @objc
        func invoke(gesture: UIGestureRecognizer) {
            (gesture as? GestureType).flatMap { self.action($0) }
        }
    }

    private struct Storage {
        private static var key = 0

        static let table = AssociatedProxyTable<UIGestureRecognizer, NSObject>(key: &Self.key)
    }
}

extension UIGestureRecognizer {
	func remove() {
		self.view?.removeGestureRecognizer(self)
	}
}
