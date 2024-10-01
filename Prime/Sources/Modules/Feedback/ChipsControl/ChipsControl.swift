import UIKit

extension ChipsControl {
	struct Appearance: Codable {
		var titleFont = Palette.shared.body3

		var titleColorNormal = Palette.shared.gray0
		var titleColorSelected = Palette.shared.gray5

		var backgroundColorNormal = Palette.shared.clear
		var backgroundColorSelected = Palette.shared.brandPrimary

		var borderColorNormal = Palette.shared.gray2
		var borderColorSelected = Palette.shared.brandPrimary
	}
}

final class ChipsControl: UIControl {
	private let appearance: Appearance

	private var stackView = UIStackView.vertical()

	var onSelectionChanged: (([Int]) -> Void)?
	var titles: [String] {
		didSet {
			self.mustUpdateLayout = true
			self.updateChips()
			self.setNeedsLayout()
		}
	}

	var selection: Array<Int> = [] {
		didSet {
			self.onSelectionChanged?(Array(self.selection))
			self.sendActions(for: .valueChanged)

			self.mustUpdateLayout = true
			self.updateChips()
			self.setNeedsLayout()
		}
	}

	private var chips = [UIView]()
	private var mustUpdateLayout = false

	init(
		appearance: Appearance = Theme.shared.appearance(),
		titles: [String] = []
	) {
		self.titles = titles
		self.appearance = appearance

		super.init(frame: .zero)
		self.placeSubviews()
		self.updateChips()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private var latestBounds: CGRect?

	override func layoutSubviews() {
		super.layoutSubviews()

		if self.mustUpdateLayout || self.latestBounds?.width != self.bounds.width {
			self.updateStackView()
			self.mustUpdateLayout = false
		}

		self.latestBounds = self.bounds
	}

	private func placeSubviews() {
		self.addSubview(self.stackView)
		self.stackView.make(.edges, .equalToSuperview, priorities: [.defaultHigh])

		self.stackView.spacing = 10
		self.stackView.alignment = .leading
	}

	private func updateChips() {
		self.chips = self.titles.enumerated().map { pair in
			self.makeChip(pair.offset, pair.element)
		}
	}

	private func updateStackView() {
		self.stackView.removeArrangedSubviews()
		var currentRowStack = with(UIStackView.horizontal()) { $0.spacing = 10; $0.alignment = .leading }
		self.stackView.addArrangedSubview(currentRowStack)

		self.chips.forEach { chip in
			currentRowStack.setNeedsLayout()
			currentRowStack.layoutIfNeeded()
			
			let arrangedSubviews = currentRowStack.arrangedSubviews

			var rowWidth = arrangedSubviews.last?.frame.maxX ?? 0
            if !arrangedSubviews.isEmpty { rowWidth += self.stackView.spacing }

			let chipWidth = chip.sizeFor(height: CGFloat.greatestFiniteMagnitude).width

			if self.stackView.bounds.width >= rowWidth + chipWidth {
				currentRowStack.addArrangedSubview(chip)
				return
			}

			currentRowStack = with(UIStackView.horizontal()) { $0.spacing = 10; $0.alignment = .leading }
			currentRowStack.addArrangedSubview(chip)

			self.stackView.addArrangedSubview(currentRowStack)
		}
	}

	private func makeChip(_ index: Int, _ title: String) -> UIView {
		UIView { view in
			var isSelected = self.selection.contains(index)

			view.layer.cornerRadius = 6
			view.layer.borderWidth = 0.5

			let titleLabel = UILabel { (label: UILabel) in
				label.fontThemed = self.appearance.titleFont
				label.text = title
			}

			view.addSubview(titleLabel)
			titleLabel.make(.edges, .equalToSuperview, [10.5, 20, -10.5, -20])

			self.colorize(chip: view, isSelected: isSelected)

			view.addTapHandler { [weak self] in
				guard let self else { return }
				
				if self.selection.contains(index) {
					self.selection.removeAll{ $0 == index }
				} else {
					self.selection.append(index)
				}

				isSelected = !isSelected

				self.colorize(chip: view, isSelected: isSelected)
				self.onSelectionChanged?(Array(self.selection))
				self.sendActions(for: .valueChanged)
			}
		}
	}

	private func colorize(chip view: UIView, isSelected: Bool) {
		view.layer.borderColorThemed = isSelected ? self.appearance.borderColorSelected
												  : self.appearance.borderColorNormal

		view.backgroundColorThemed = isSelected ? self.appearance.backgroundColorSelected
												: self.appearance.backgroundColorNormal

		if let label = view.firstSubviewOf(type: UILabel.self) {
			label.textColorThemed = isSelected ? self.appearance.titleColorSelected
											   : self.appearance.titleColorNormal
		}
	}
}

