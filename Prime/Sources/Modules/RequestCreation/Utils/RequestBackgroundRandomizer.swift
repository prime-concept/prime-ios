import UIKit

final class RequestBackgroundRandomizer {
	static func image(named name: String, range: ClosedRange<Int>) -> UIImage? {
		var index: Int = range.lowerBound

		let previousWallpaperIndexKey = "request_wallpaper_\(name)"

		if range.count > 1 {
			let indexToAvoid = UserDefaults.standard.integer(forKey: previousWallpaperIndexKey)
			while true {
				index = range.randomElement() ?? index
				if index != indexToAvoid {
					break
				}
			}
		}

		UserDefaults.standard.set(index, forKey: previousWallpaperIndexKey)
		let wallpaperName = name + "_\(index)"

		return UIImage.init(named: wallpaperName) ?? UIImage.init(named: name) 
	}
}
