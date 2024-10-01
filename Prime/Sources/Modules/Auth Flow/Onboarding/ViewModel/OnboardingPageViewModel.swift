import Foundation

protocol OnboardingPageViewModel {
    var currentPageIndex: Int { get }
    var numberOfPages: Int { get }
}

struct OnboardingTextContentViewModel: OnboardingPageViewModel {
    var currentPageIndex: Int
    var numberOfPages: Int
    let headline: String
    let number: String
    let title: String
    let firstParagraph: String?
    let secondParagraph: String?
    let dotTexts: [String]
    let subTitle: String?
    let image: String?

    init(
        currentPageIndex: Int,
        numberOfPages: Int,
        headline: String,
        number: String,
        title: String,
        firstParagraph: String? = nil,
        secondParagraph: String? = nil,
        dotTexts: [String] = [],
        subTitle: String? = nil,
        image: String? = nil
    ) {
        self.currentPageIndex = currentPageIndex
        self.numberOfPages = numberOfPages
        self.headline = headline
        self.number = number
        self.title = title
        self.firstParagraph = firstParagraph
        self.secondParagraph = secondParagraph
        self.dotTexts = dotTexts
        self.subTitle = subTitle
        self.image = image
    }
}

struct OnboardingStarContentViewModel: OnboardingPageViewModel {
    var currentPageIndex: Int
    var numberOfPages: Int
    let image: String
    let title: String
    let firstParagraph: String
    let secondParagraph: String?

    init(
        currentPageIndex: Int,
        numberOfPages: Int,
        image: String,
        title: String,
        firstParagraph: String,
        secondParagraph: String? = nil
    ) {
        self.currentPageIndex = currentPageIndex
        self.numberOfPages = numberOfPages
        self.image = image
        self.title = title
        self.firstParagraph = firstParagraph
        self.secondParagraph = secondParagraph
    }
}
