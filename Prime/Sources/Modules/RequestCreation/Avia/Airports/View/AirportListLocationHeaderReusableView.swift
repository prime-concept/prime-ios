import UIKit

final class AirportListLocationHeaderReusableView: UICollectionReusableView, Reusable {
    var onArrowButtonTap: (() -> Void)?
    private lazy var headerView = AirportListLocationHeaderView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: AirportListHeaderViewModel) {
        self.headerView.setup(with: viewModel)
        headerView.disclosureIndicatorButtonTap = { [weak self] in
            self?.onArrowButtonTap?()
        }
    }
}

extension AirportListLocationHeaderReusableView: Designable {
    func addSubviews() {
        self.addSubview(self.headerView)
    }

    func makeConstraints() {
        self.headerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
