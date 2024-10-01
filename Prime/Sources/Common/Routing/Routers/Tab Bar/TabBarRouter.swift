import Foundation
import UIKit

class TabBarRouter: SourcelessRouter, RouterProtocol {
    private var tab: Int

    init(tab: Int) {
        self.tab = tab
    }

    func route() {
        self.currentTabBarController?.selectedIndex = tab
    }
}
