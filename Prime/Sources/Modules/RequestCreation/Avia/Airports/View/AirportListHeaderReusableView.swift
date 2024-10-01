import UIKit

final class AirportListHeaderReusableView: UICollectionReusableView, Reusable {
    private lazy var headerView: AirportListHeaderView = {
        let view = AirportListHeaderView()
        return view
    }()

    var title: String = "" {
        didSet {
            headerView.title = title
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AirportListHeaderReusableView: Designable {
    func addSubviews() {
        self.addSubview(headerView)
    }

    func makeConstraints() {
        headerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
