import UIKit

class HomeBannerViewModel: RequestListDisplayableModel {
	class Banner {
		init(id: String, imageURL: String? = nil, link: String, onTap: @escaping (Int?) -> Void) {
			self.id = id
			self.imageURL = imageURL
			self.link = link
			self.onTap = onTap
		}

		let id: String
		let link: String
		let imageURL: String?
		var image: UIImage? = nil

		let onTap: (Int?) -> Void
	}

	init(banners: [HomeBannerViewModel.Banner]) {
		self.banners = banners
	}

	var id: String {
		self.banners.map(\.id).joined(separator: ",")
	}

	let banners: [Banner]

	var isTriple: Bool {
		self.banners.count == 3
	}
}
