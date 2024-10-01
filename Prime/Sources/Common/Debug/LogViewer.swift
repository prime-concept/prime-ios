import UIKit

class LogViewer: UIViewController {
	private(set) lazy var textView = UITextView()

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = .white

		self.view.addSubview(self.textView)

        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
		self.textView.isEditable = false
		self.textView.make(.edges, .equal, to: self.view.safeAreaLayoutGuide, [0, 10, 0, -10])
	}

	func scrollToBottom() {
		let range = NSMakeRange(self.textView.text.lengthOfBytes(using: .utf8), 0);
		self.textView.scrollRangeToVisible(range);
	}
}


