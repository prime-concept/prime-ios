import Foundation
import UIKit

extension PersonsDetailInfoView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.clear
        var separatorBackgroundColor = Palette.shared.gray3
        var titleTextColor = Palette.shared.gray0
        var subtitleTextColor = Palette.shared.brandPrimary
    }
}

final class PersonsDetailInfoView: UIView {
    private lazy var nameLabel = UILabel()
    private lazy var birthLabel = UILabel()
    private lazy var topSeparatorView = OnePixelHeightView()
    private lazy var bottomSeparatorView = OnePixelHeightView()
    private let appearance: Appearance
    
    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupInfo(with viewModel: PersonInfoViewModel) {
        self.isHidden = false
        self.nameLabel.attributedTextThemed = viewModel.fullName
            .attributed()
            .foregroundColor(appearance.titleTextColor)
            .primeFont(ofSize: 16, weight: .regular, lineHeight: 20)
            .string()
        self.birthLabel.attributedTextThemed = viewModel.birthDate
            .attributed()
            .foregroundColor(appearance.subtitleTextColor)
            .primeFont(ofSize: 14, weight: .regular, lineHeight: 17)
            .string()
    }
}

extension PersonsDetailInfoView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.topSeparatorView.backgroundColorThemed = self.appearance.separatorBackgroundColor
        self.bottomSeparatorView.backgroundColorThemed = self.appearance.separatorBackgroundColor
    }

    func addSubviews() {
        [
            self.nameLabel,
            self.birthLabel,
            self.topSeparatorView,
            self.bottomSeparatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.topSeparatorView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }
        self.nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self.topSeparatorView.snp.bottom).offset(14)
            make.leading.equalToSuperview().inset(15)
            make.trailing.equalToSuperview().offset(10)
        }
        self.birthLabel.snp.makeConstraints { make in
            make.top.equalTo(self.nameLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().inset(15)
        }
        self.bottomSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(self.birthLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
