import UIKit

final class CalendarRequestItemCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var calendarRequestItemView = CalendarRequestItemView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: CalendarRequestItemViewModel) {
        self.calendarRequestItemView.setup(with: viewModel)
    }

    // MARK: - Private

    private func setupView() {
        self.contentView.backgroundColorThemed = Palette.shared.clear
    }

    private func addSubviews() {
        self.contentView.addSubview(self.calendarRequestItemView)
    }

    private func makeConstraints() {
        self.calendarRequestItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
