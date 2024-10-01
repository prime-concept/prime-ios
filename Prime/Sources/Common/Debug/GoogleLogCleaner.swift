import UIKit
import Firebase
import FirebaseDatabase

class GoogleLogCleaner {
	// Оставляем shared, это безопасно, тк тут нет стейта зависимого от сессии юзера
	static let shared = GoogleLogCleaner()
	private var googleDBsToClear = [Firebase.DatabaseReference]()

	func cleanOlderThan14Days() {
		let firstDayToKeep = Date() + (-15).days
		DebugUtils.shared.log("START CLEANING GOOGLE DB LOGS")

		self.clearGoogleDB(
			year: firstDayToKeep[.year],
			month: firstDayToKeep[.month],
			start: 0,
			end: firstDayToKeep[.day],
			progress: {
				DebugUtils.shared.log("CLEANING GOOGLE DB LOGS: \($0)")
			},
			completion: {
				DebugUtils.shared.log("END CLEANING GOOGLE DB LOGS")
			}
		)
	}

	fileprivate func clearGoogleDB(
		year: Int,
		month: Int,
		start: Int? = nil,
		end: Int? = nil,
		progress: ((String) -> Void)? = nil,
		completion: @escaping () -> Void
	) {
		let start = start ?? 1
		let end = end ?? 31

		var month = month.description
		if month.count == 1 { month = "0\(month)" }

		self.googleDBsToClear = (start...end).compactMap { day in
			var day = day.description
			if day.count == 1 { day = "0\(day)" }
			return FirebaseUtils.logsDB(year: year.description, month: month, day: day)
		}

		var count = self.googleDBsToClear.count

        // swiftlint:disable:next empty_count
		if count == 0 {
			completion()
			return
		}

		self.googleDBsToClear.forEach { db in
			db.removeValue { error, _ in
				let date = "\(year)-\(month)/\(db.key^)"
				if let error {
					progress?("\(date) - FAILED! \(error.localizedDescription)")
				} else {
					progress?("\(date) - OK!")
				}
				DispatchQueue.main.async {
					count -= 1;
                    // swiftlint:disable:next empty_count
					if count == 0 {
						completion(); self.googleDBsToClear.removeAll()
					}
				}
			}
		}
	}
}

class GoogleLogCleanerViewController: UIViewController {
	private var year: String = ""
	private var month: String = ""
	private var dayStart: String = "1"
	private lazy var dayEnd: String = (Date() + (-31).days)[.day].description

	private lazy var textView = UITextView()
	private let cleaner = GoogleLogCleaner()

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = .white

		let safeDate = Date() + (-1).months

		self.year = safeDate.string("YYYY")
		self.month = safeDate.string("MM")

		let label = UILabel()
		label.textColor = .darkGray
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		label.text = "Это форма ручной очистки логов в Realtime Database в Фаербейсе. Вам нужно вписать год, месяц и дни для очистки логов. Если не указать дни - будет очищен весь месяц.\n\n\"Токен\" приложения: \(FirebaseUtils.appDBName)"

		self.view.addSubview(label)
		label.make(.edges(except: .bottom), .equal, to: self.view.safeAreaLayoutGuide, [20, 20, -20])


		textView.isEditable = false

		let stack = UIStackView.horizontal(
			self.makeTextField(text: self.year) { [unowned self] in self.year = $0.text ?? self.year },
			self.makeTextField(text: self.month, width: 33) { [unowned self] in self.month = $0.text ?? self.month },
			self.makeTextField(text: self.dayStart, width: 33) { [unowned self] in self.dayStart = $0.text ?? self.dayStart },
			self.makeTextField(text: self.dayEnd, width: 33) { [unowned self] in self.dayEnd = $0.text ?? self.dayEnd },
			with(UIButton(type: .custom)) { clearButton in
				clearButton.backgroundColor = .red
				clearButton.setTitleColor(.white, for: .normal)
				clearButton.setTitle("ОЧИСТИТЬ", for: .normal)
				clearButton.setEventHandler(for: .touchUpInside) { [unowned self] in
					self.handleClearButton()
				}
			}
		)

		stack.spacing = 10
		self.view.addSubview(stack)
		stack.place(under: label, +20)
		stack.make(.hEdges, .equal, to: label)

		self.view.addSubview(textView)
		textView.place(under: stack, +20)
		textView.make(.hEdges, .equal, to: label)
		textView.make(.bottom, .equal, to: self.view.safeAreaLayoutGuide)
	}
}

extension GoogleLogCleanerViewController {
	private func handleClearButton() {
		guard let year = Int(self.year) else {
			AlertPresenter.alert(message: "Заполните год!", actionTitle: "ОК")
			return
		}

		guard let month = Int(self.month) else {
			AlertPresenter.alert(message: "Заполните месяц!", actionTitle: "ОК")
			return
		}

		self.showLoadingIndicator()
		self.view.endEditing(true)
		self.textView.text = ""

		self.cleaner.clearGoogleDB(
			year: year,
			month: month,
			start: Int(self.dayStart),
			end: Int(self.dayEnd),
			progress: {
				self.textView.text.append($0 + "\n")
			}) { [unowned self] in
				self.hideLoadingIndicator()
				self.textView.text.append("DONE!")
			}
	}

	private func makeTextField(
		text: String,
		keyboardType: UIKeyboardType = .numberPad,
		width: CGFloat? = nil,
		handler: ((UITextField) -> Void)? = nil
	) -> UIView {
		let textField = UITextField()
		textField.text = text

		textField.setEventHandler(for: .editingChanged) {
			handler?(textField)
		}

		textField.keyboardType = keyboardType
		textField.layer.borderWidth = 1
		textField.layer.cornerRadius = 2
		textField.layer.borderColorThemed = Palette.shared.brandPrimary
		textField.textColorThemed = Palette.shared.mainBlack

		textField.textAlignment = .center

		textField.make(.size, .equal, [width ?? 60, 33])

		return textField
	}
}
