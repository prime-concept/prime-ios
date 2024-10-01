import Foundation
import UIKit

class ExpensesHeader: UITableViewHeaderFooterView, Reusable {
    let title = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureContents()
    }
	@available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setDateTitle(date: Date) {
        let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd.MM.yy"
        title.attributedTextThemed = dateFormatter.string(from: date).attributed()
            .primeFont(ofSize: 12, lineHeight: 14)
            .foregroundColor(.systemGray)
            .string()
    }
    func configureContents() {
        self.contentView.backgroundColorThemed = Palette.shared.gray5
        contentView.addSubview(title)
        title.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(5)
            make.top.equalToSuperview().inset(25)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}
