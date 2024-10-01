import UIKit

extension Notification.Name {
	static let didTapOnFeedback = Notification.Name("didTapOnFeedback")
	static let didTapOnTaskHeader = Notification.Name("didTapOnTaskHeader")
	static let didTapOnTaskMessage = Notification.Name("didTapOnTaskMessage")
}

extension RequestListView {
    struct Appearance: Codable {
        var collectionMinimumLineSpacing: CGFloat = 0
        var collectionBackgroundColor = Palette.shared.clear
        var collectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

final class RequestListView: UIView {
	fileprivate enum Constants {
		static let offsetValue = CGFloat(157.0)
		static let differenceValue = CGFloat(56)
		static let itemsSizeCacheFile = "RequestListView.itemsSizeCache"
	}

	private static var headersSizeCache = [RequestListHeaderViewModel: CGSize]()
	private static var bannersSizeCache = [String: CGSize]()

	@PersistentCodable(fileName: Constants.itemsSizeCacheFile, async: false)
	private static var itemsSizeCache = [String: CGSize]()

	private lazy var contentView = UIView()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = self.appearance.collectionMinimumLineSpacing
        layout.minimumLineSpacing = self.appearance.collectionMinimumLineSpacing
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.contentInset = self.appearance.collectionInset
        collectionView.refreshControl = GlobeRefreshControl()
        collectionView.refreshControl?.setEventHandler(for: .valueChanged) { [weak self] in
            self?.onRefreshList?()
        }

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(cellClass: RequestListItemCollectionViewCell.self)
		collectionView.register(cellClass: HomeBannerCollectionViewCell.self)
        collectionView.register(
            viewClass: RequestListHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )

		collectionView.contentInset.bottom = 147

        return collectionView
    }()

    private lazy var emptyStateView = with(RequestListEmptyView()) { view in
        view.addTapHandler(feedback: .scale) { [weak self] in self?.onEmptyListTap?() }
    }

    private let appearance: Appearance

	@ThreadSafe
	private var data = [any RequestListDisplayableModel]()
    private var header: RequestListHeaderViewModel?
	private var headerView: RequestListHeaderView?
	private var bannersCount = 0

    private var isReached: Bool = false

    var onListScroll: ((_ listScrolledDown: Bool) -> Void)?
    var onOpenGeneralChat: (() -> Void)?
    var onOpenPayFilter: (() -> Void)?
    var onOpenCompletedTasks: (() -> Void)?
    var onPaymentTap: ((Int) -> Void)?
	var onPromoCategoryTap: ((Int) -> Void)?
    var onRefreshList: (() -> Void)?
    var onEmptyListTap: (() -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(viewModel: RequestCreationRequestListViewModel) {
		self.data = viewModel.banners + viewModel.requestViewModels
		self.bannersCount = viewModel.banners.count

        self.header = nil

		self.reloadData()

		DebugUtils.shared.log(sender: self, "REQUEST LIST VIEW WILL RELOAD!")

		if self.data.isEmpty {
            self.updateAsEmpty()
        } else {
            self.updateAsPopulated()
        }
    }

    func update(viewModel: HomeViewModel) {
		let viewModel = viewModel

		self.header = viewModel.requestsListHeader

		let singleBanners = viewModel.banners.skip(\.isTriple) as [any RequestListDisplayableModel]
		let tripleBanners = viewModel.banners.filter(\.isTriple) as [any RequestListDisplayableModel]
		var requests = viewModel.requests as [any RequestListDisplayableModel]

		if !tripleBanners.isEmpty {
			let insertionIndex = min(2, requests.count)
			requests.insert(contentsOf: tripleBanners, at: insertionIndex)
		}

		self.data = singleBanners + requests
		self.bannersCount = viewModel.banners.count

        self.collectionView.refreshControl?.endRefreshing()
		
        if self.data.isEmpty {
            self.updateAsEmpty()
			return
        }

		self.updateAsPopulated()
    }

    // MARK: - Private

	private func invalidateCachedSizes(
		oldData: [any RequestListDisplayableModel],
		newData: [any RequestListDisplayableModel],
		indicesOfUpdated: Set<Int>
	) {
		let visibleTasksIndices = self.collectionView.indexPathsForVisibleItems.map(\.row)
		let indices = indicesOfUpdated.union(Set(visibleTasksIndices))

		for index in indices {
			if let item = self.data[safe: index] as? RequestListItemViewModel {
				let cacheKey = self.cacheKey(for: item)
				if let cacheKey { Self.itemsSizeCache.removeValue(forKey: cacheKey) }
			}
		}
	}

	/**
	 В этом методе мы ищем, а не поменялась ли в модели какая-нибудь таска, соответствующая видимым на
	 данный момент таскам на экране. Поменялась == заменилась на другую таску.
	 Если заменилась - надо перезагрузить коллекцию.
	 */
	private func visibleItemsChanged(
		oldData: [any RequestListDisplayableModel],
		newData: [any RequestListDisplayableModel]
	) -> Bool {
		let visibleIndices = self.collectionView.indexPathsForVisibleItems.map(\.row)

		let oldCacheKeys = visibleIndices
			.compactMap{ oldData[safe: $0] }
			.compactMap{ self.cacheKey(for: $0) }

		let newCacheKeys = visibleIndices
			.compactMap{ newData[safe: $0] }
			.compactMap{ self.cacheKey(for: $0) }

		let changed = oldCacheKeys != newCacheKeys
		return changed
	}

	private func bannersChanged(oldBanners: [HomeBannerViewModel], newBanners: [HomeBannerViewModel]) -> Bool {
		let oldBannersKeys = oldBanners.compactMap{ self.cacheKey(for: $0) }
		let newBannersKeys = newBanners.compactMap{ self.cacheKey(for: $0) }

		let changed = oldBannersKeys != newBannersKeys
		return changed
	}

    private func updateAsEmpty() {
        self.emptyStateView.isHidden = false
		self.contentView.bringSubviewToFront(self.emptyStateView)
		self.reloadData()
    }

	private func updateAsPopulated(reloadData: Bool = true) {
        self.emptyStateView.isHidden = true
		self.contentView.bringSubviewToFront(self.collectionView)

		if reloadData {
			self.reloadData()
		} else {
			DebugUtils.shared.log("WILL SKIP TIRESOME TASK LIST RELOAD!!!")
			self.updateHeaderView()
		}
    }

	private lazy var reloadThrottler = Throttler(
		timeout: 1,
		executesPendingAfterCooldown: true
	) { [weak self] in
		DebugUtils.shared.log("TIRESOME RELOAD DATA!")
		self?.collectionView.reloadData()
	}

	private func reloadData() {
		self.reloadThrottler.execute()
	}

	private func updateHeaderView() {
		self.headerView?.onOpenGeneralChat = self.onOpenGeneralChat
		self.headerView?.onOpenPayFilter = self.onOpenPayFilter
		self.headerView?.onOpenCompletedTasks = self.onOpenCompletedTasks
		self.header.flatMap { self.headerView?.update(viewModel: $0) }
	}
}

extension RequestListView: Designable {
    func addSubviews() {
		self.addSubview(self.contentView)
		self.contentView.addSubview(self.emptyStateView)
		self.contentView.addSubview(self.collectionView)
    }

    func makeConstraints() {
		self.contentView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}

        self.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.emptyStateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension RequestListView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        self.data.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
		guard let item = self.data[safe: indexPath.row] else {
			return UICollectionViewCell()
		}

		let collectionViewCell: UICollectionViewCell

		if let item = item as? RequestListItemViewModel {
			let cell: RequestListItemCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

			cell.setup(with: item, onOrderViewTap: { [weak self] in
				self?.onPaymentTap?($0)
			}, onPromoCategoryTap: { [weak self] in
				self?.onPromoCategoryTap?($0)
			})
			collectionViewCell = cell
		} else if let item = item as? HomeBannerViewModel {
			let cell: HomeBannerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
			let isLastCell = indexPath.row == self.bannersCount - 1

			let diminishesTopInset = indexPath.row == 0

			cell.setup(
				with: item,
				extendsBottomInset: isLastCell,
				diminishesTopInset: diminishesTopInset
			)
			collectionViewCell = cell
		} else {
			fatalError("RequestListView UNKNOWN ITEM TYPE: \(type(of: item))")
		}
		
		// Фикс релейаута ячеек при появлении на скролле
		UIView.performWithoutAnimation {
			collectionViewCell.layoutIfNeeded()
		}

        return collectionViewCell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.removeTapHandler()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
		let item = self.data[safe: indexPath.row]

        guard let item = item else {
            return .zero
        }

		var size = CGSize.zero

		if let item = item as? RequestListItemViewModel {
			let cacheKey = self.cacheKey(for: item)
			if let cacheKey, let cachedSize = Self.itemsSizeCache[cacheKey] {
				return cachedSize
			}

			let cell = RequestListItemCollectionViewCell.reference
			cell.setup(with: item, onOrderViewTap: { _ in }, onPromoCategoryTap: { _ in })
			size = cell.sizeFor(width: collectionView.bounds.width)

			if let cacheKey { Self.itemsSizeCache[cacheKey] = size }
		}

		if let item = item as? HomeBannerViewModel {
			if let cachedSize = Self.bannersSizeCache[item.id] {
				return cachedSize
			}

			let cell = HomeBannerCollectionViewCell.reference
			let isLastCell = indexPath.row == self.bannersCount - 1
			let diminishesTopInset = indexPath.row == 0

			cell.setup(
				with: item,
				extendsBottomInset: isLastCell,
				diminishesTopInset: diminishesTopInset
			)

			size = cell.sizeFor(width: collectionView.bounds.width)

			Self.bannersSizeCache[item.id] = size
		}
		
		return size
    }

	private func cacheKey(for requestItem: any RequestListDisplayableModel) -> String? {
		if let bannerModel = requestItem as? HomeBannerViewModel {
			return "Banner ID: \(bannerModel.id)"
		}

		guard let requestItem = requestItem as? RequestListItemViewModel else {
			return nil
		}

		var cacheKey = "Task. ID: \(requestItem.id), orders: \(requestItem.orders.count), promos: \(requestItem.promoCategories.count)"

		with(requestItem.headerViewModel) { header in
			cacheKey.append(", title: \(header.title ?? ""), subtitle: \(header.subtitle ?? ""), date: \(header.formattedDate ?? ""), booked: \(header.hasReservation), completed: \(header.isCompleted)")
		}

		with(requestItem.lastMessageViewModel) { lastMessage in
			guard let lastMessage else { return }
			cacheKey.append(", last message: \(lastMessage.text), icon: \(lastMessage.icon?.size ?? .zero)")
		}

		if let feedbackViewModel = requestItem.feedbackViewModel {
			cacheKey.append(", feedback: (\(feedbackViewModel.title), taskCompleted: \(feedbackViewModel.taskCompleted))")
		}

		return cacheKey
	}

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
		guard kind == UICollectionView.elementKindSectionHeader else {
			fatalError("No header")
		}

		let view: RequestListHeaderView = collectionView.dequeueReusableSupplementaryView(
			ofKind: kind, for: indexPath
		)

		self.headerView = view

		self.updateHeaderView()

		return view
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
		guard let headerModel = self.header else {
			return CGSize.zero
		}

		if let cachedSize = Self.headersSizeCache[headerModel] {
			return cachedSize
		}

		let header = RequestListHeaderView.reference
		header.update(viewModel: headerModel)

		let size = header.sizeFor(width: collectionView.bounds.width)

		Self.headersSizeCache[headerModel] = size
		return size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            return
        }

		if scrollView.contentOffset.y > Constants.offsetValue {
            self.isReached = true
            self.onListScroll?(true)
        } else {
            if self.isReached {
				if scrollView.contentOffset.y + Constants.differenceValue > Constants.offsetValue {
                    self.onListScroll?(true)
                } else {
                    self.isReached = false
                    self.onListScroll?(false)
                }
            } else {
                self.onListScroll?(false)
            }
        }
    }
}
