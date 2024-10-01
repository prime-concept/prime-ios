import UIKit

final class PinCodeInput: UIView {
	private(set) var pin = ""
	var keyboardType: UIKeyboardType = .numberPad

	private var pinCodeDots: [PinCodeDot] = []
	private var mayAcceptDigit: Bool = true

	private let pinCount: Int
    private let debounceDelay: TimeInterval

	init(pinCount: Int = 4, debounceDelay: TimeInterval = 0.5) {
		self.pinCount = pinCount
		self.debounceDelay = debounceDelay

		super.init(frame: .zero)

		self.setupView()
	}

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = 20
        return view
    }()

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 15)
    }

    var hasError: Bool = false {
        didSet {
            self.pin = ""
            self.update()
        }
    }

    var onPinEntered: ((String) -> Void)?

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
	func clearPins() {
		self.pinCodeDots.forEach {
			$0.pinState = .normal
		}
	}

	func fillPins() {
		self.pinCodeDots.forEach {
			$0.pinState = .selected
		}
	}

    func clear() {
        self.pin = ""

        self.pinCodeDots.forEach {
            $0.pinState = .normal
        }
    }

    // MARK: - Private API

    private func setupView() {
		self.pinCodeDots = (0..<pinCount).map { _ in
			let dot = PinCodeDot()
			dot.make(.size, .equal, [15, 15])
			return dot
		}

        self.addSubview(self.stackView)
        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
		self.stackView.addArrangedSubviews(self.pinCodeDots)
    }

    private func append(character: String) {
        guard self.pin.count != self.pinCount else {
            return
        }

        if self.hasError {
            self.hasError = false
        }

        self.pin.append(character)
        self.update()

        if self.pin.count != self.pinCount {
            return
        }

		delay(self.debounceDelay) {
			self.onPinEntered?(self.pin)
		}
    }

    private func clearLastPin() {
        if self.hasError {
            self.hasError = false
            self.update()
            return
        }

		self.pin.removeLast()
        self.update()
    }

    private func update() {
        let pinCount = self.pin.count

        for (index, pinView) in self.pinCodeDots.enumerated() {
            if self.hasError {
                pinView.pinState = .error
				continue
            }

			pinView.pinState = (index < pinCount) ? .selected : .normal
        }
    }
}

extension PinCodeInput: UIKeyInput {
	override var canBecomeFirstResponder: Bool {
		return true
	}

	var hasText: Bool {
		!pin.isEmpty
	}

	func insertText(_ text: String) {
		guard self.mayAcceptDigit else {
			return
		}

		self.mayAcceptDigit = false

		delay(0.1) {
			self.mayAcceptDigit = true
		}

		append(character: text)
	}

	func deleteBackward() {
		guard self.mayAcceptDigit else {
			return
		}

		self.mayAcceptDigit = false

		delay(0.1) {
			self.mayAcceptDigit = true
		}

		if self.hasText {
			self.clearLastPin()
		}
	}
}
