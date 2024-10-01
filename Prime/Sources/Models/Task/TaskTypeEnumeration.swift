import UIKit

typealias TaskTypeFilter = [TaskTypeEnumeration]

enum TaskTypeEnumeration: String, CaseIterable {
    case all
    case buyCar
    case airlineLoyaltyProgramm
    case aeroflotAvia
    case pat
    case avia
    case helicopter
    case lowCost
    case privateJet
    case airportServices
    case baggage
    case checkIn
    case loyaltyProgrammInfo
    case servicesOnBoard
    case ticketModification
    case alcohol
    case animals
    case financialSupport
    case jurispredenceSupport
    case shoppingAndGifts
    case things
    case jewelry
    case additionalEducation
    case educationPlanning
    case prePrimaryEducation
    case schools
    case summerCamps
    case catering
    case eventOrganization
    case ritual
    case beautySalons
    case spa
    case checkUpBody
    case firstAid
    case stomatology
    case hospital
    case hotel
    case trip
    case addressPhone
    case bankInfo
    case documentSupport
    case goodsSearch
    case gosUslugi
    case lostNfound
    case pharmacy
    case schedule
    case secretary
    case transportInfo
    case weather
    case otherInsurance
    case travelInsurance
    case beeline
    case pondMobile
    case eventsList
    case sights
    case weekendEventsList
    case other
    case buyAndSell
    case rent
    case nightlife
    case restaurants
    case restaurantsContent
    case highLife
    case tickets
    case carRental
    case chaufferService
    case transfer
    case passport
    case visa
    case visaDocuments
    case booking
    case cinema
    case delivery
    case ferry
    case flowers
    case guidedTour
    case invitations
    case primeDesign
    case staff
    case train
    case translation
    case vipLounge
    case yachtRent

    case goldCardIssue
    case restaurantsAndClubs
    case restaurantsReserve
    case easyLife
    case platinumCardIssue
    case clientActivation
    case corporateMembership
    case newMembership
    case foodDelivery
    case partnerComplaint
    case partnerComment
    case clientComplaint
    case clientComment
    case complaintBonus
    case complaint
    case cardsAeroflotProlongation
    case cardsAeroflotNew
    case platinumProlongation
    case platinumNew
    case goldGiftProlongation
    case goldGiftNew
    case primeWine
    case membershipProlongation
    case modifications
    case entryRegulations

    case general
    case others

    init?(id: Int) {
        if let type = TaskTypeEnumeration.allCases.first(where: { $0.id == id }) {
            self = type
        } else {
            return nil
        }
    }
}

extension TaskTypeEnumeration {
    var defaultLocalizedName: String {
        let key = "createTask." + self.rawValue
        return key.localized
    }
}

extension TaskTypeEnumeration {
    var id: Int {
        switch self {
        case .all:
            return 1
        case .buyCar:
            return 268435705
        case .airlineLoyaltyProgramm:
            return 268435601
        case .aeroflotAvia:
            return 268435594
        case .pat:
            return 268435670
        case .avia:
            return 16
        case .helicopter:
            return 43
        case .lowCost:
            return 268435577
        case .privateJet:
            return 53
        case .airportServices:
            return 268435714
        case .baggage:
            return 268435717
        case .checkIn:
            return 268435713
        case .loyaltyProgrammInfo:
            return 268435716
        case .servicesOnBoard:
            return 268435715
        case .ticketModification:
            return 268435718
        case .alcohol:
            return 72
        case .animals:
            return 68
        case .financialSupport:
            return 59
        case .jurispredenceSupport:
            return 61
        case .shoppingAndGifts:
            return 13
        case .things:
            return 65
        case .jewelry:
            return 70
        case .additionalEducation:
            return 102
        case .educationPlanning:
            return 104
        case .prePrimaryEducation:
            return 100
        case .schools:
            return 101
        case .summerCamps:
            return 103
        case .catering:
            return 79
        case .eventOrganization:
            return 31
        case .ritual:
            return 92
        case .beautySalons:
            return 94
        case .spa:
            return 93
        case .checkUpBody:
            return 95
        case .firstAid:
            return 96
        case .stomatology:
            return 98
        case .hospital:
            return 97
        case .hotel:
            return 12
        case .trip:
            return 268435710
        case .addressPhone:
            return 74
        case .bankInfo:
            return 268435635
        case .documentSupport:
            return 60
        case .goodsSearch:
            return 268435637
        case .gosUslugi:
            return 268435636
        case .lostNfound:
            return 73
        case .pharmacy:
            return 69
        case .schedule:
            return 76
        case .secretary:
            return 268435634
        case .transportInfo:
            return 268435633
        case .weather:
            return 67
        case .otherInsurance:
            return 268435569
        case .travelInsurance:
            return 18
        case .beeline:
            return 42
        case .pondMobile:
            return 268435607
        case .eventsList:
            return 55
        case .sights:
            return 268435632
        case .weekendEventsList:
            return 268435672
        case .other:
            return 268435591
        case .buyAndSell:
            return 26
        case .rent:
            return 268435573
        case .nightlife:
            return 5
        case .restaurants:
            return 9
        case .restaurantsContent:
            return 268435630
        case .highLife:
            return 268435603
        case .tickets:
            return 49
        case .carRental:
            return 30
        case .chaufferService:
            return 268435707
        case .transfer:
            return 90
        case .passport:
            return 91
        case .visa:
            return 19
        case .visaDocuments:
            return 268435629
        case .booking:
            return 268435706
        case .cinema:
            return 3
        case .delivery:
            return 24
        case .ferry:
            return 268435720
        case .flowers:
            return 268435595
        case .guidedTour:
            return 20
        case .invitations:
            return 268435567
        case .primeDesign:
            return 268435592
        case .staff:
            return 47
        case .train:
            return 17
        case .translation:
            return 268435626
        case .vipLounge:
            return 51
        case .yachtRent:
            return 52
        case .goldCardIssue:
            return 268435622
        case .restaurantsAndClubs:
            return 268435574
        case .easyLife:
            return 268435579
        case .platinumCardIssue:
            return 268435623
        case .clientActivation:
            return 268435589
        case .corporateMembership:
            return 268435602
        case .newMembership:
            return 268435563
        case .foodDelivery:
            return 268435722
        case .partnerComplaint:
            return 268435587
        case .partnerComment:
            return 268435588
        case .clientComplaint:
            return 268435585
        case .clientComment:
            return 268435586
        case .complaintBonus:
            return 268435709
        case .complaint:
            return 268435621
        case .cardsAeroflotProlongation:
            return 268435608
        case .cardsAeroflotNew:
            return 268435609
        case .platinumProlongation:
            return 268435612
        case .platinumNew:
            return 268435611
        case .goldGiftProlongation:
            return 268435614
        case .goldGiftNew:
            return 268435613
        case .primeWine:
            return 268435708
        case .membershipProlongation:
            return 268435561
        case .modifications:
            return 268435755
        case .restaurantsReserve:
            return 268435721
        case .entryRegulations:
            return 268435756
        case .others, .general:
            return 1000
        }
    }
}

extension TaskTypeEnumeration {
    var defaultImage: UIImage? {
        switch self {
        case .all:
            return nil
        case .buyCar, .carRental, .transfer:
            return UIImage(named: "car_icon")
        case .aeroflotAvia:
            return UIImage(named: "airplane_generic") //aeroflot_avia
        case .airlineLoyaltyProgramm:
            return UIImage(named: "airline_loyalty_program_icon")
        case .airportServices, .baggage, .checkIn, .loyaltyProgrammInfo, .servicesOnBoard, .ticketModification:
            return UIImage(named: "avia_services_icon")
        case .animals:
            return UIImage(named: "animals_icon")
        case .beautySalons:
            return UIImage(named: "beauty_icon")
        case .cinema:
            return UIImage(named: "cinema_icon")
        case .delivery, .foodDelivery:
            return UIImage(named: "delivery_icon")
        case .chaufferService:
            return UIImage(named: "chauffeur_icon")
        case .additionalEducation, .educationPlanning, .prePrimaryEducation, .schools, .summerCamps:
            return UIImage(named: "education_icon")
        case .documentSupport, .gosUslugi:
            return UIImage(named: "docs_support_icon")
        case .financialSupport:
            return UIImage(named: "financial_support_icon")
        case .ferry:
            return UIImage(named: "ferry_icon")
        case .shoppingAndGifts:
            return UIImage(named: "gifts_icon")
        case .flowers:
            return UIImage(named: "flowers_icon")
        case .checkUpBody, .firstAid, .stomatology, .hospital, .pharmacy:
            return UIImage(named: "health_icon")
        case .guidedTour:
            return UIImage(named: "guided_tour_icon")
        case .buyAndSell, .rent:
            return UIImage(named: "home_icon")
        case .helicopter:
            return UIImage(named: "helicopter_icon")
        case .eventsList, .sights, .weekendEventsList, .addressPhone,
                .bankInfo, .goodsSearch, .lostNfound, .secretary,
                .schedule, .transportInfo, .weather, .pat,
                .booking, .pondMobile, .beeline, .modifications:
            return UIImage(named: "info_icon")
        case .hotel:
            return UIImage(named: "hotel_icon")
        case .invitations:
            return UIImage(named: "invitations_icon")
        case .otherInsurance, .travelInsurance:
            return UIImage(named: "insurance_icon")
        case .jurispredenceSupport:
            return UIImage(named: "judge_suppot_icon")
        case .jewelry:
            return UIImage(named: "jewelry_icon")
        case .nightlife:
            return UIImage(named: "nightlife_icon")
        case .lowCost:
            return UIImage(named: "low_cost_icon")
        case .visa, .passport, .visaDocuments, .entryRegulations:
            return UIImage(named: "visa_passport_icon")
        case .other:
            return UIImage(named: "other_icon")
        case .privateJet:
            return UIImage(named: "jet_icon")
        case .primeDesign:
            return UIImage(named: "prime_design_icon")
        case .staff, .translation:
            return UIImage(named: "staff_icon")
        case .spa:
            return UIImage(named: "spa_icon")
        case .restaurants, .restaurantsContent, .restaurantsAndClubs, .restaurantsReserve:
            return UIImage(named: "restaurants_icon")
        case .train:
            return UIImage(named: "train_icon")
        case .things:
            return UIImage(named: "things_icon")
        case .alcohol:
            return UIImage(named: "wine_icon")
        case .vipLounge:
            return UIImage(named: "vip_icon")
        case .trip:
            return UIImage(named: "trip_icon")
        case .yachtRent:
            return UIImage(named: "yacht_rent_icon")
        case .avia:
            return UIImage(named: "avia_icon")
        case .catering, .eventOrganization:
            return UIImage(named: "catering_icon")
        case .ritual:
            return UIImage(named: "ritual_icon")
        case .tickets, .highLife:
            return UIImage(named: "tickets_icon")
        case .primeWine:
            return UIImage(named: "sommelier_icon")
        case .newMembership: /*, .clientActivation, .platinumCardIssue, .clientActivation, .corporateMembership, .goldGiftNew, .platinumNew, .cardsAeroflotNew */
            return UIImage(named: "membership_new_icon")
        case .membershipProlongation: /*, .goldGiftProlongation, platinumProlongation, cardsAeroflotProlongation */
            return UIImage(named: "membership_renew_icon")
        case .partnerComment, .clientComment:
            return UIImage(named: "client_comment_icon")
        case .clientComplaint, .partnerComplaint, .complaintBonus, .complaint:
            return UIImage(named: "client_complaint_icon")
        case .others:
            return nil
        default:
            return nil
        }
    }
}

extension TaskTypeEnumeration {
    static let aviaTypes: TaskTypeFilter = [
        .avia,
        .baggage,
        .checkIn,
        .loyaltyProgrammInfo,
        .servicesOnBoard,
        .ticketModification,
        .airlineLoyaltyProgramm,
        .aeroflotAvia,
        .helicopter,
        .lowCost,
        .privateJet,
        .airportServices
    ]
}

extension TaskTypeEnumeration {
    static func filter(for type: TaskTypeEnumeration) -> TaskTypeFilter? {
        if type == .avia {
            return aviaTypes
        }

        if aviaTypes.contains(type) {
            return nil
        }

        if type == .all {
            return nil
        }

        return [type]
    }

    /// Имя категории, пришедшее с бэка. Если нет - то локализованное имя.
    var correctName: String {
        TaskType.localizedName(for: self.id) ?? self.defaultLocalizedName
    }
}

extension Optional where Wrapped == TaskTypeEnumeration {
    var defaultImage: UIImage? {
        switch self {
        case .some(let type):
            return type.defaultImage
        case .none:
            return UIImage(named: "default_task_type_icon")
        }
    }
}
