import UIKit

struct FamilyEditTextFieldModel {
    let title: String
    let placeholder: String
    let value: String
    let onUpdate: (String) -> Void
}

extension FamilyEditFieldView {
    struct Appearance: Codable {
        var neutralSeparatorColor = Palette.shared.gray3
        var activeSeparatorColor = Palette.shared.gray0
        var textColor = Palette.shared.gray0
        var titleTextColor = Palette.shared.gray1
    }
}

final class FamilyEditFieldView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        return textField
    }()
    
    private var model: FamilyEditTextFieldModel?
    
    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.neutralSeparatorColor
        return view
    }()

    private lazy var containerView = UIView()
    private let appearance: Appearance
    
    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with viewModel: FamilyEditTextFieldModel) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(viewModel.title)
        self.textField.attributedPlaceholder = Self.makePlaceholder(viewModel.placeholder)
        self.textField.attributedTextThemed = Self.makeValue(viewModel.value)
        self.textField.setEventHandler(for: .editingChanged) { [weak self] in
            self?.textField.text.flatMap { text in
                viewModel.onUpdate(text)
				self?.textField.updateKeepingCursor {
					self?.textField.attributedTextThemed = Self.makeValue(text)
				}
            }
        }
    }
}

extension FamilyEditFieldView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.titleLabel,
            self.textField,
            self.separatorView
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.textField.snp.top).offset(-2)
        }

        self.textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-10)
        }
    }
    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, lineHeight: 15)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }

    private static func makePlaceholder(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0.withAlphaComponent(0.3))
            .string()
    }

    private static func makeValue(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }
}

extension FamilyEditFieldView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25) {
            self.separatorView.backgroundColorThemed = Palette.shared.gray0
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25) {
            self.separatorView.backgroundColorThemed = Palette.shared.gray3
        }
    }
}
