import UIKit

class Theme: Codable {
	static let shared = Theme()

	// Modules/DetailCalendar/Controller/RequestCell/DetailCalendarNoDataCell.swift
	private(set) var detailCalendarNoDataCellAppearance = DetailCalendarNoDataCell.Appearance()

	private(set) var layerBackgroundViewAppearance = LayerBackgroundView.Appearance()
	private(set) var taskAccessoryButtonAppearance = TaskAccessoryButton.Appearance()

	// Tabs/FloatingControlsView.swift
	private(set) var floatingControlsViewAppearance = FloatingControlsView.Appearance()

	// Common/ViewControllers/DragableViewController.swift
	private(set) var dragableViewControllerAppearance = DragableViewController.Appearance()

	// Modules/Home/Controller/HomeView.swift
	private(set) var homeViewAppearance = HomeView.Appearance()

	// Modules/Home/Views/Calendar/CalendarRequestItem/CalendarRequestItemView.swift
	private(set) var calendarRequestItemViewAppearance = CalendarRequestItemView.Appearance()

	// Modules/Home/Views/Calendar/DayItem/CalendarDayItemView.swift
	private(set) var calendarDayItemViewAppearance = CalendarDayItemView.Appearance()

	// Modules/Home/Views/Calendar/HomeCalendarView.swift
	private(set) var homeCalendarViewAppearance = HomeCalendarView.Appearance()

	// Modules/Home/Views/RequestList/RequestListItemView/RequestListItemView.swift
	private(set) var requestListItemViewAppearance = RequestListItemView.Appearance()

	// Modules/Home/Views/RequestList/RequestItemMainView/PaymentButtonsView.swift
	private(set) var paymentButtonsViewAppearance = PaymentButtonsView.Appearance()

	// Modules/Home/Views/RequestList/RequestItemMainView/RequestItemLastMessageView.swift
	private(set) var requestItemLastMessageViewAppearance = RequestItemLastMessageView.Appearance()

	// Modules/Home/Views/RequestList/RequestItemMainView/RequestItemMainView.swift
	private(set) var requestItemMainViewAppearance = RequestItemMainView.Appearance()

	// Modules/Home/Views/RequestList/RequestListHeaderView.swift
	private(set) var requestListHeaderViewAppearance = RequestListHeaderView.Appearance()

	// Modules/Home/Views/RequestList/RequestListView.swift
	private(set) var requestListViewAppearance = RequestListView.Appearance()

	// Modules/Home/Views/RequestList/RequestListEmptyView.swift
	private(set) var requestListEmptyViewAppearance = RequestListEmptyView.Appearance()

	// Modules/Home/Views/Header/PayItem/HomePayItemView.swift
	private(set) var homePayItemViewAppearance = HomePayItemView.Appearance()

	// Modules/Home/Views/Header/HomeHeaderView.swift
	private(set) var homeHeaderViewAppearance = HomeHeaderView.Appearance()

	// Modules/Tasks/Controller/TasksTabViewController.swift
	private(set) var tasksTabViewControllerAppearance = TasksTabViewController.Appearance()

	// Modules/Tasks/Views/TasksListHeaderView.swift
	private(set) var tasksListHeaderViewAppearance = TasksListHeaderView.Appearance()

	// Modules/Tasks/Views/TasksListView.swift
	private(set) var tasksListViewAppearance = TasksListView.Appearance()

	// Modules/Chat/TaskDetails/TaskDetailsView.swift
	private(set) var taskDetailsViewAppearance = TaskDetailsView.Appearance()

	// Modules/Chat/TaskDetails/TaskDetailsViewController.swift
	private(set) var taskDetailsViewControllerAppearance = TaskDetailsViewController.Appearance()

    // Modules/Auth Flow/Enter Card/CardNumberView.swift
    private(set) var cardNumberViewAppearance = CardNumberView.Appearance()

    // Modules/Auth Flow/Acquaintance/EnterInfoView.swift
    private(set) var enterInfoViewAppearance = EnterInfoView.Appearance()
    
    // Modules/Auth Flow/Acquaintance/AcquaintanceView.swift
    private(set) var acquaintanceViewAppearance = AcquaintanceView.Appearance()
    
	// Modules/Auth Flow/Enter PinCode/View/PinCodeView.swift
	private(set) var pinCodeViewAppearance = PinCodeView.Appearance()
    
    // Modules/Auth Flow/Enter PinCode/Views/PinItemPoint.swift
    private(set) var pinCodeDotAppearance = PinCodeDot.Appearance()
    
	// Modules/Auth Flow/Enter Phone/View/PhoneNumberView.swift
	private(set) var phoneNumberViewAppearance = PhoneNumberView.Appearance()

	// Modules/Auth Flow/Enter Phone/View/Views/EnterPhoneView/EnterPhoneView.swift
	private(set) var enterPhoneViewAppearance = EnterPhoneView.Appearance()
    
    // Modules/Auth Flow/Enter Phone/View/Views/TermView.swift
    private(set) var termViewAppearance = TermView.Appearance()

	// Modules/Auth Flow/ContactPrime/View/ContactPrimeView.swift
	private(set) var contactPrimeViewAppearance = ContactPrimeView.Appearance()
    
    // Modules/Auth Flow/ContactPrime/View/PrimeButton.swift
    private(set) var primeButtonAppearance = PrimeButton.Appearance()
    
	// Modules/Auth Flow/Verify Phone/SMSCodeView.swift
	private(set) var SMSCodeViewAppearance = SMSCodeView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/OnboardingPageView.swift
	private(set) var onboardingPageViewAppearance = OnboardingPageView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/OnboardingStarContentView.swift
	private(set) var onboardingStarContentViewAppearance = OnboardingStarContentView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/SecondReasonView.swift
	private(set) var secondReasonViewAppearance = SecondReasonView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/ThirdReasonView.swift
	private(set) var thirdReasonViewAppearance = ThirdReasonView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/FifthReasonView.swift
	private(set) var fifthReasonViewAppearance = FifthReasonView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/FourthReasonView.swift
	private(set) var fourthReasonViewAppearance = FourthReasonView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/OnboardingView.swift
	private(set) var onboardingViewAppearance = OnboardingView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/OnboardingTextContentView.swift
	private(set) var onboardingTextContentViewAppearance = OnboardingTextContentView.Appearance()

	// Modules/Auth Flow/Onboarding/Views/FirstReasonView.swift
	private(set) var firstReasonViewAppearance = FirstReasonView.Appearance()

	// Modules/Expenses/Cells/ExpensesTableViewCell.swift
	private(set) var expensesTableViewCellAppearance = ExpensesTableViewCell.Appearance()

	// Modules/Expenses/ExpensesNoDataView.swift
	private(set) var expensesNoDataViewAppearance = ExpensesNoDataView.Appearance()

	// Modules/Cards/Controllers/CardViewController.swift
	private(set) var cardViewControllerAppearance = CardViewController.Appearance()

	// Modules/Cards/Controllers/Cells/CardsTableViewCell.swift
	private(set) var cardsTableViewCellAppearance = CardsTableViewCell.Appearance()

	// Modules/Cards/Controllers/CardsViewController.swift
	private(set) var cardsViewControllerAppearance = CardsViewController.Appearance()

	// Modules/RequestCreation/Hotel/Form/Views/HotelFormView.swift
	private(set) var hotelFormViewAppearance = HotelFormView.Appearance()

	// Modules/RequestCreation/Hotel/Form/Views/HotelFormRowView.swift
	private(set) var hotelFormRowViewAppearance = HotelFormRowView.Appearance()

	// Modules/RequestCreation/Hotel/Hotels/HotelCityItemView.swift
	private(set) var hotelCityItemViewAppearance = HotelCityItemView.Appearance()

	// Modules/RequestCreation/Hotel/Hotels/HotelItemView.swift
	private(set) var hotelItemViewAppearance = HotelItemView.Appearance()

	// Modules/RequestCreation/Hotel/Hotels/HotelListHeaderView.swift
	private(set) var hotelsListHeaderViewAppearance = HotelsListHeaderView.Appearance()

	// Modules/RequestCreation/Hotel/Hotels/HotelsListView.swift
	private(set) var hotelsListViewAppearance = HotelsListView.Appearance()

	// Modules/RequestCreation/Hotel/Guests/Views/HotelGuestsViewController.swift
	private(set) var hotelGuestsViewControllerAppearance = HotelGuestsViewController.Appearance()

	// Modules/RequestCreation/Avia/AviaRouteSelection/AviaRouteSelectionViewController.swift
	private(set) var aviaRouteSelectionViewControllerAppearance = AviaRouteSelectionViewController.Appearance()

	// Modules/RequestCreation/Avia/AviaRouteSelection/Views/AviaRouteSelectionItemView.swift
	private(set) var aviaRouteSelectionItemViewAppearance = AviaRouteSelectionItemView.Appearance()

	// Modules/RequestCreation/Avia/Avia Form/Views/TextFields/AviaDatePickerFieldView.swift
	private(set) var aviaDatePickerFieldViewAppearance = AviaDatePickerFieldView.Appearance()

	// Modules/RequestCreation/Avia/Avia Form/Views/TextFields/AviaPickerFieldView.swift
	private(set) var aviaPickerFieldViewAppearance = AviaPickerFieldView.Appearance()

	// Modules/RequestCreation/Avia/Avia Form/Views/AviaModalView.swift
	private(set) var aviaModalViewAppearance = AviaModalView.Appearance()
    
    // Modules/RequestCreation/VIP Lounge/VIP Lounge Form/Views/VIPLoungeModelView.swift
    private(set) var vipLoungeModelViewAppearance = VIPLoungeView.Appearance()

	// Modules/RequestCreation/Avia/Avia Form/Views/AviaMultiCityRowView.swift
	private(set) var aviaMultiCityRowViewAppearance = AviaMultiCityRowView.Appearance()
	private(set) var aviaMultiCityCellViewAppearance = AviaMultiCityCellView.Appearance()

	// Modules/RequestCreation/Avia/Avia Form/Views/AddFlightButton.swift
	private(set) var addFlightButtonAppearance = AddFlightButton.Appearance()

	// Modules/RequestCreation/Avia/Airports/Controller/AirportListViewController.swift
	private(set) var airportListViewControllerAppearance = AirportListViewController.Appearance()

	// Modules/RequestCreation/Avia/Airports/View/AirportListHeaderView.swift
	private(set) var airportListHeaderViewAppearance = AirportListHeaderView.Appearance()

	// Modules/RequestCreation/Avia/Airports/View/AirportListLocationHeaderView.swift
	private(set) var airportListLocationHeaderViewAppearance = AirportListLocationHeaderView.Appearance()

	// Modules/RequestCreation/Avia/Airports/View/AirportItemView.swift
	private(set) var airportItemViewAppearance = AirportItemView.Appearance()

	// Modules/RequestCreation/Avia/Airports/View/AirportListView.swift
	private(set) var airportListViewAppearance = AirportListView.Appearance()
    
    // Modules/RequestCreation/Avia/Avia Form/Views/AviaFlipView.swift
    private(set) var aviaFlipViewAppearance = AviaFlipView.Appearance()

	// Modules/RequestCreation/Main/View/RequestCreationView.swift
	private(set) var requestCreationButtonAppearance = RequestCreationButton.Appearance()

	// Modules/RequestCreation/Main/View/TaskAccessoryHeaderView.swift
//	private(set) var taskAccessoryHeaderViewAppearance = TaskAccessoryHeaderView.Appearance()

	// Modules/RequestCreation/Main/View/RequestCreationDefaultOverlayView.swift
	private(set) var requestCreationDefaultOverlayViewAppearance = RequestCreationDefaultOverlayView.Appearance()

	// Modules/FamilyEdit/FormFields/FamilyEditDateFieldView.swift
	private(set) var familyEditDateFieldViewAppearance = FamilyEditDateFieldView.Appearance()

	// Modules/FamilyEdit/FormFields/FamilyEditPickerFieldView.swift
	private(set) var familyEditPickerFieldViewAppearance = FamilyEditPickerFieldView.Appearance()

	// Modules/FamilyEdit/FormFields/FamilyEditFieldView.swift
	private(set) var familyEditFieldViewAppearance = FamilyEditFieldView.Appearance()

	// Modules/FamilyEdit/PersonEditViewController.swift
	private(set) var personEditViewControllerAppearance = PersonEditViewController.Appearance()

	// Modules/AviaPassengersModal/ViewController/AviaPassengersViewController.swift
	private(set) var aviaPassengersViewControllerAppearance = AviaPassengersViewController.Appearance()

	// Modules/Profile/ContactsList/Controller/ContactsListTabsViewController.swift
	private(set) var contactsListTabsViewControllerAppearance = ContactsListTabsViewController.Appearance()

	// Modules/Profile/ContactsList/Views/ContactsListView.swift
	private(set) var contactsListViewAppearance = ContactsListView.Appearance()

	// Modules/Profile/ContactsList/Views/ContactsListTableViewCell.swift
	private(set) var contactsListTableViewCellAppearance = ContactsListTableViewCell.Appearance()

	// Modules/Profile/Main Page/Controller/ProfileTabsViewController.swift
	private(set) var profileTabsViewControllerAppearance = ProfileTabsViewController.Appearance()

	// Modules/Profile/Main Page/Views/ProfilePersonalInfoListView.swift
	private(set) var profilePersonalInfoListViewAppearance = ProfilePersonalInfoListView.Appearance()

	// Modules/Profile/Main Page/Views/ProfilePersonalInfoTableViewCell.swift
	private(set) var profilePersonalInfoTableViewCellAppearance = ProfilePersonalInfoTableViewCell.Appearance()
	private(set) var profilePersonInfoEmptyInfoViewAppearance = ProfilePersonInfoEmptyInfoView.Appearance()

	// Modules/Profile/Main Page/Views/ProfileView.swift
	private(set) var profileViewAppearance = ProfileView.Appearance()

	// Modules/Profile/Main Page/Views/QRView.swift
	private(set) var qRViewAppearance = QRView.Appearance()

	// Modules/Profile/Main Page/Views/ProfileCardView.swift
	private(set) var profileCardViewAppearance = ProfileCardView.Appearance()

	// Modules/Profile/Main Page/Views/AddedToWalletView.swift
	private(set) var addedToWalletViewAppearance = AddedToWalletView.Appearance()

	// Modules/Profile/Profile Settings/Settings List/ProfileSettingsViewController.swift
	private(set) var profileSettingsViewControllerAppearance = ProfileSettingsViewController.Appearance()
    
    // Modules/Profile/Profile Settings/Settings List/ProfileSettingsTableViewCell.swift
    private(set) var profileSettingsTableViewCellAppearance = ProfileSettingsTableViewCell.Appearance()

	// Modules/Profile/ContactAddition/ContactTypeSelection/ContactTypeSelectionItemView/ContactTypeSelectionItemView.swift
	private(set) var contactTypeSelectionItemViewAppearance = ContactTypeSelectionItemView.Appearance()

	// Modules/Profile/ContactAddition/ContactTypeSelection/Controller/ContactTypeSelectionViewController.swift
	private(set) var contactTypeSelectionViewControllerAppearance = ContactTypeSelectionViewController.Appearance()

	// Modules/Profile/ContactAddition/Views/ContactAdditionFieldView.swift
	private(set) var contactAdditionFieldViewAppearance = ContactAdditionFieldView.Appearance()

	// Modules/Profile/ContactAddition/Views/ContactAdditionView.swift
	private(set) var contactAdditionViewAppearance = ContactAdditionView.Appearance()

	// Modules/Profile/ContactAddition/Views/ContactAdditionSwitchFieldView.swift
	private(set) var contactAdditionSwitchFieldViewAppearance = ContactAdditionSwitchFieldView.Appearance()

	// Modules/Profile/ContactAddition/Views/ContactAdditionCodeSelectionFieldView.swift
	private(set) var contactAdditionCodeSelectionFieldViewAppearance = ContactAdditionCodeSelectionFieldView.Appearance()

	// Modules/Profile/ContactAddition/Views/ContactAdditionPhoneFieldView.swift
	private(set) var contactAdditionPhoneFieldViewAppearance = ContactAdditionPhoneFieldView.Appearance()
    
    // Modules/Profile/Profile Settings/Profile Edit/ProfileEditViewController.swift
    private(set) var profileEditViewAppearance = ProfileEditViewController.Appearance()

	// Modules/DetailRequestCreation/Controller/DetailRequestCreationView.swift
	private(set) var detailRequestCreationViewAppearance = DetailRequestCreationView.Appearance()

	// Modules/DetailRequestCreation/Views/TimeZonePickerView.swift
	private(set) var timeZonePickerViewAppearance = TimeZonePickerView.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationSeparatorView.swift
	private(set) var detailRequestCreationSeparatorViewAppearance = DetailRequestCreationSeparatorView.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationSelectionView.swift
	private(set) var detailRequestCreationSelectionViewAppearance = DetailRequestCreationSelectionView.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationCheckboxView.swift
	private(set) var detailRequestCreationCheckboxViewAppearance = DetailRequestCreationCheckboxView.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationTimeWithTimeZoneView.swift
	private(set) var detailRequestCreationTimeWithTimeZoneViewAppearance = DetailRequestCreationTimeWithTimeZoneView.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationUnsupportedView.swift
	private(set) var detailRequestCreationUnsupportedViewAppearance = DetailRequestCreationUnsupportedView.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationFieldNoticeView.swift
	private(set) var detailRequestCreationFieldNoticeViewAppearance = DetailRequestCreationFieldNoticeView.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationTextField.swift
	private(set) var detailRequestCreationTextFieldAppearance = DetailRequestCreationTextField.Appearance()

	// Modules/DetailRequestCreation/Views/DetailRequestCreationTextView.swift
	private(set) var detailRequestCreationTextViewAppearance = DetailRequestCreationTextView.Appearance()

	// Modules/Catalog item selection/CatalogItemSelectionViewController.swift
	private(set) var catalogItemSelectionViewControllerAppearance = CatalogItemSelectionViewController.Appearance()

	// Modules/DetailCalendar/Controller/RequestCell/DetailCalendarRequestTableViewCell.swift
	private(set) var detailCalendarRequestSectionHeaderViewAppearance = DetailCalendarRequestSectionHeaderView.Appearance()

	// Modules/DetailCalendar/Controller/DetailCalendarView.swift
	private(set) var detailCalendarViewAppearance = DetailCalendarView.Appearance()

	// Modules/DetailCalendar/Views/FSCalendarView.swift
	private(set) var fSCalendarViewAppearance = FSCalendarView.Appearance()

	// Modules/DetailCalendar/Views/Header/DetailCalendarHeaderView.swift
	private(set) var detailCalendarHeaderViewAppearance = DetailCalendarHeaderView.Appearance()

	// Modules/CountryCodes/CountryCodeItemView/CountryCodeItemView.swift
	private(set) var countryCodeItemViewAppearance = CountryCodeItemView.Appearance()

	// Modules/CountryCodes/CountryCodesViewController.swift
	private(set) var countryCodesViewControllerAppearance = CountryCodesViewController.Appearance()

	// Modules/Selection/Controller/SelectionView.swift
	private(set) var selectionViewAppearance = SelectionView.Appearance()

	// Modules/Selection/Views/SelectionItemView.swift
	private(set) var selectionItemViewAppearance = SelectionItemView.Appearance()

	// Modules/Persons/Controllers/PersonsDetailInfoView.swift
	private(set) var personsDetailInfoViewAppearance = PersonsDetailInfoView.Appearance()

	// Modules/Persons/Controllers/PersonsViewController.swift
	private(set) var personsViewControllerAppearance = PersonsViewController.Appearance()

	// Modules/Persons/Controllers/PersonsInfoView.swift
	private(set) var personsInfoViewAppearance = PersonsInfoView.Appearance()
	private(set) var emptyPersonsInfoViewAppearance = EmptyPersonsInfoView.Appearance()

	// Modules/Documents/Controllers/DocumentsViewController.swift
	private(set) var documentsViewControllerAppearance = DocumentsViewController.Appearance()

	// Modules/Documents/Controllers/DocumentViewController.swift
	private(set) var documentViewControllerAppearance = DocumentViewController.Appearance()

	// Modules/CardEdit/CardEditViewController.swift
	private(set) var cardEditViewControllerAppearance = CardEditViewController.Appearance()

	// Modules/CardEdit/Cells/CardEditFieldView.swift
	private(set) var cardEditFieldViewAppearance = CardEditFieldView.Appearance()

	// Modules/CardEdit/Cells/CardEditPickerFieldView.swift
	private(set) var cardEditPickerFieldViewAppearance = CardEditPickerFieldView.Appearance()

	// Modules/DocumentEdit/DocumentEditViewController.swift
	private(set) var documentEditViewControllerAppearance = DocumentEditViewController.Appearance()

	// Modules/RangeSelectionCalendar/FSCalendarRangeSelectionViewController.swift
	private(set) var fSCalendarRangeSelectionViewControllerAppearance = FSCalendarRangeSelectionViewController.Appearance()

	// Modules/RangeSelectionCalendar/FSCalendarRangeSelectionCell.swift
	private(set) var fSCalendarRangeSelectionCellAppearance = FSCalendarRangeSelectionCell.Appearance()

	// Views/TaskInfoTypeView/TaskInfoTypeView.swift
	private(set) var taskInfoTypeViewAppearance = TaskInfoTypeView.Appearance()

	// Views/Chat/ChatNavigationBar.swift
	private(set) var chatNavigationBarAppearance = ChatNavigationBar.Appearance()

    // Views/Chat/CustomNavigationBar.swift
    private(set) var customNavigationBarAppearance = LeftTitleCustomNavigationBar.Appearance()

	// Views/NewRequestsView.swift
	private(set) var newRequestsViewAppearance = NewRequestsView.Appearance()

	// Views/SearchTextField.swift
	private(set) var searchTextFieldAppearance = SearchTextField.Appearance()

	// Views/GrabberView.swift
	private(set) var grabberViewAppearance = GrabberView.Appearance()

	// Views/CountButton.swift
	private(set) var countButtonAppearance = CountButton.Appearance()

	// Views/ShadowContainerView.swift
	private(set) var shadowContainerViewAppearance = ShadowContainerView.Appearance()

	private(set) var сontactPrimeNotificationViewAppearance = ContactPrimeNotificationView.Appearance()
    
    // Views/CustomSegmentView/CustomSegmentView.swift
    private(set) var customSegmentViewAppearance = CustomSegmentView.Appearance()
	private(set) var expandedCalendarEventViewAppearance = DetailCalendarEventView.Appearance()
	private(set) var starsControlAppearance = StarsControl.Appearance()
	private(set) var chipsControlAppearance = ChipsControl.Appearance()
	private(set) var primeTextViewComponentAppearance = PrimeTextViewComponent.Appearance()
	private(set) var filledActionButtonAppearance = FilledActionButton.Appearance()

	private(set) var feedbackViewAppearance = FeedbackView.Appearance()
	private(set) var feedbackRatingViewAppearance = FeedbackRatingView.Appearance()
	private(set) var feedbackDetailsViewAppearance = FeedbackDetailsView.Appearance()
	private(set) var feedbackSuccessViewAppearance = FeedbackSuccessView.Appearance()
	private(set) var feedbackStarsContainerAppearance = FeedbackStarsContainer.Appearance()
    private(set) var unreadCountBadgeAppearance = UnreadCountBadge.Appearance()

	private(set) var curtainViewAppearance = CurtainView.Appearance()

	private(set) var fullImageViewControllerAppearance = FullImageViewControllerAppearance()
}

extension Theme {
	func update(from jsonFile: String) {
        guard
            let path = Bundle.main.path(forResource: jsonFile, ofType: ".json"),
            let json = try? String(contentsOfFile: path),
            let data = json.data(using: .utf8),
            let instance = try? JSONDecoder().decode(Theme.self, from: data)
        else { return }
		
		self.detailCalendarNoDataCellAppearance = instance.detailCalendarNoDataCellAppearance
		self.layerBackgroundViewAppearance = instance.layerBackgroundViewAppearance
		self.taskAccessoryButtonAppearance = instance.taskAccessoryButtonAppearance
		self.floatingControlsViewAppearance = instance.floatingControlsViewAppearance
		self.dragableViewControllerAppearance = instance.dragableViewControllerAppearance
		self.homeViewAppearance = instance.homeViewAppearance
		self.calendarRequestItemViewAppearance = instance.calendarRequestItemViewAppearance
		self.calendarDayItemViewAppearance = instance.calendarDayItemViewAppearance
		self.homeCalendarViewAppearance = instance.homeCalendarViewAppearance
		self.requestListItemViewAppearance = instance.requestListItemViewAppearance
		self.paymentButtonsViewAppearance = instance.paymentButtonsViewAppearance
		self.requestItemLastMessageViewAppearance = instance.requestItemLastMessageViewAppearance
		self.requestItemMainViewAppearance = instance.requestItemMainViewAppearance
		self.requestListHeaderViewAppearance = instance.requestListHeaderViewAppearance
		self.requestListViewAppearance = instance.requestListViewAppearance
		self.requestListEmptyViewAppearance = instance.requestListEmptyViewAppearance
		self.homePayItemViewAppearance = instance.homePayItemViewAppearance
		self.homeHeaderViewAppearance = instance.homeHeaderViewAppearance
		self.tasksTabViewControllerAppearance = instance.tasksTabViewControllerAppearance
		self.tasksListHeaderViewAppearance = instance.tasksListHeaderViewAppearance
		self.tasksListViewAppearance = instance.tasksListViewAppearance
		self.taskDetailsViewAppearance = instance.taskDetailsViewAppearance
		self.taskDetailsViewControllerAppearance = instance.taskDetailsViewControllerAppearance
        self.cardNumberViewAppearance = instance.cardNumberViewAppearance
		self.pinCodeViewAppearance = instance.pinCodeViewAppearance
        self.pinCodeDotAppearance = instance.pinCodeDotAppearance
        self.enterInfoViewAppearance = instance.enterInfoViewAppearance
        self.acquaintanceViewAppearance = instance.acquaintanceViewAppearance
		self.phoneNumberViewAppearance = instance.phoneNumberViewAppearance
		self.enterPhoneViewAppearance = instance.enterPhoneViewAppearance
        self.termViewAppearance = instance.termViewAppearance
		self.contactPrimeViewAppearance = instance.contactPrimeViewAppearance
        self.primeButtonAppearance = instance.primeButtonAppearance
		self.SMSCodeViewAppearance = instance.SMSCodeViewAppearance
		self.onboardingPageViewAppearance = instance.onboardingPageViewAppearance
		self.onboardingStarContentViewAppearance = instance.onboardingStarContentViewAppearance
		self.secondReasonViewAppearance = instance.secondReasonViewAppearance
		self.thirdReasonViewAppearance = instance.thirdReasonViewAppearance
		self.fifthReasonViewAppearance = instance.fifthReasonViewAppearance
		self.fourthReasonViewAppearance = instance.fourthReasonViewAppearance
		self.onboardingViewAppearance = instance.onboardingViewAppearance
		self.onboardingTextContentViewAppearance = instance.onboardingTextContentViewAppearance
		self.firstReasonViewAppearance = instance.firstReasonViewAppearance
		self.expensesTableViewCellAppearance = instance.expensesTableViewCellAppearance
		self.expensesNoDataViewAppearance = instance.expensesNoDataViewAppearance
		self.cardViewControllerAppearance = instance.cardViewControllerAppearance
		self.cardsTableViewCellAppearance = instance.cardsTableViewCellAppearance
		self.cardsViewControllerAppearance = instance.cardsViewControllerAppearance
		self.hotelFormViewAppearance = instance.hotelFormViewAppearance
		self.hotelFormRowViewAppearance = instance.hotelFormRowViewAppearance
		self.hotelCityItemViewAppearance = instance.hotelCityItemViewAppearance
		self.hotelItemViewAppearance = instance.hotelItemViewAppearance
		self.hotelsListHeaderViewAppearance = instance.hotelsListHeaderViewAppearance
		self.hotelsListViewAppearance = instance.hotelsListViewAppearance
		self.hotelGuestsViewControllerAppearance = instance.hotelGuestsViewControllerAppearance
		self.aviaRouteSelectionViewControllerAppearance = instance.aviaRouteSelectionViewControllerAppearance
		self.aviaRouteSelectionItemViewAppearance = instance.aviaRouteSelectionItemViewAppearance
		self.aviaDatePickerFieldViewAppearance = instance.aviaDatePickerFieldViewAppearance
		self.aviaPickerFieldViewAppearance = instance.aviaPickerFieldViewAppearance
		self.aviaModalViewAppearance = instance.aviaModalViewAppearance
        self.vipLoungeModelViewAppearance = instance.vipLoungeModelViewAppearance
		self.aviaMultiCityRowViewAppearance = instance.aviaMultiCityRowViewAppearance
		self.aviaMultiCityCellViewAppearance = instance.aviaMultiCityCellViewAppearance
		self.addFlightButtonAppearance = instance.addFlightButtonAppearance
		self.airportListViewControllerAppearance = instance.airportListViewControllerAppearance
		self.airportListHeaderViewAppearance = instance.airportListHeaderViewAppearance
		self.airportListLocationHeaderViewAppearance = instance.airportListLocationHeaderViewAppearance
		self.airportItemViewAppearance = instance.airportItemViewAppearance
		self.airportListViewAppearance = instance.airportListViewAppearance
        self.aviaFlipViewAppearance = instance.aviaFlipViewAppearance
		self.requestCreationButtonAppearance = instance.requestCreationButtonAppearance
		self.requestCreationDefaultOverlayViewAppearance = instance.requestCreationDefaultOverlayViewAppearance
		self.familyEditDateFieldViewAppearance = instance.familyEditDateFieldViewAppearance
		self.familyEditPickerFieldViewAppearance = instance.familyEditPickerFieldViewAppearance
		self.familyEditFieldViewAppearance = instance.familyEditFieldViewAppearance
		self.personEditViewControllerAppearance = instance.personEditViewControllerAppearance
		self.aviaPassengersViewControllerAppearance = instance.aviaPassengersViewControllerAppearance
		self.contactsListTabsViewControllerAppearance = instance.contactsListTabsViewControllerAppearance
		self.contactsListViewAppearance = instance.contactsListViewAppearance
		self.contactsListTableViewCellAppearance = instance.contactsListTableViewCellAppearance
		self.profileTabsViewControllerAppearance = instance.profileTabsViewControllerAppearance
		self.profilePersonalInfoListViewAppearance = instance.profilePersonalInfoListViewAppearance
		self.profilePersonalInfoTableViewCellAppearance = instance.profilePersonalInfoTableViewCellAppearance
        self.profileSettingsTableViewCellAppearance = instance.profileSettingsTableViewCellAppearance
		self.profilePersonInfoEmptyInfoViewAppearance = instance.profilePersonInfoEmptyInfoViewAppearance
		self.profileViewAppearance = instance.profileViewAppearance
		self.qRViewAppearance = instance.qRViewAppearance
		self.profileCardViewAppearance = instance.profileCardViewAppearance
		self.addedToWalletViewAppearance = instance.addedToWalletViewAppearance
		self.profileSettingsViewControllerAppearance = instance.profileSettingsViewControllerAppearance
		self.contactTypeSelectionItemViewAppearance = instance.contactTypeSelectionItemViewAppearance
		self.contactTypeSelectionViewControllerAppearance = instance.contactTypeSelectionViewControllerAppearance
		self.contactAdditionFieldViewAppearance = instance.contactAdditionFieldViewAppearance
		self.contactAdditionViewAppearance = instance.contactAdditionViewAppearance
		self.contactAdditionSwitchFieldViewAppearance = instance.contactAdditionSwitchFieldViewAppearance
		self.contactAdditionCodeSelectionFieldViewAppearance = instance.contactAdditionCodeSelectionFieldViewAppearance
		self.contactAdditionPhoneFieldViewAppearance = instance.contactAdditionPhoneFieldViewAppearance
        self.profileEditViewAppearance = instance.profileEditViewAppearance
		self.detailRequestCreationViewAppearance = instance.detailRequestCreationViewAppearance
		self.timeZonePickerViewAppearance = instance.timeZonePickerViewAppearance
		self.detailRequestCreationSeparatorViewAppearance = instance.detailRequestCreationSeparatorViewAppearance
		self.detailRequestCreationSelectionViewAppearance = instance.detailRequestCreationSelectionViewAppearance
		self.detailRequestCreationCheckboxViewAppearance = instance.detailRequestCreationCheckboxViewAppearance
		self.detailRequestCreationTimeWithTimeZoneViewAppearance = instance.detailRequestCreationTimeWithTimeZoneViewAppearance
		self.detailRequestCreationUnsupportedViewAppearance = instance.detailRequestCreationUnsupportedViewAppearance
		self.detailRequestCreationFieldNoticeViewAppearance = instance.detailRequestCreationFieldNoticeViewAppearance
		self.detailRequestCreationTextFieldAppearance = instance.detailRequestCreationTextFieldAppearance
		self.detailRequestCreationTextViewAppearance = instance.detailRequestCreationTextViewAppearance
		self.catalogItemSelectionViewControllerAppearance = instance.catalogItemSelectionViewControllerAppearance
		self.detailCalendarRequestSectionHeaderViewAppearance = instance.detailCalendarRequestSectionHeaderViewAppearance
		self.detailCalendarViewAppearance = instance.detailCalendarViewAppearance
		self.fSCalendarViewAppearance = instance.fSCalendarViewAppearance
		self.detailCalendarHeaderViewAppearance = instance.detailCalendarHeaderViewAppearance
		self.countryCodeItemViewAppearance = instance.countryCodeItemViewAppearance
		self.countryCodesViewControllerAppearance = instance.countryCodesViewControllerAppearance
		self.selectionViewAppearance = instance.selectionViewAppearance
		self.selectionItemViewAppearance = instance.selectionItemViewAppearance
		self.personsDetailInfoViewAppearance = instance.personsDetailInfoViewAppearance
		self.personsViewControllerAppearance = instance.personsViewControllerAppearance
		self.personsInfoViewAppearance = instance.personsInfoViewAppearance
		self.emptyPersonsInfoViewAppearance = instance.emptyPersonsInfoViewAppearance
		self.documentsViewControllerAppearance = instance.documentsViewControllerAppearance
		self.documentViewControllerAppearance = instance.documentViewControllerAppearance
		self.cardEditViewControllerAppearance = instance.cardEditViewControllerAppearance
		self.cardEditFieldViewAppearance = instance.cardEditFieldViewAppearance
		self.cardEditPickerFieldViewAppearance = instance.cardEditPickerFieldViewAppearance
		self.documentEditViewControllerAppearance = instance.documentEditViewControllerAppearance
		self.fSCalendarRangeSelectionViewControllerAppearance = instance.fSCalendarRangeSelectionViewControllerAppearance
		self.fSCalendarRangeSelectionCellAppearance = instance.fSCalendarRangeSelectionCellAppearance
		self.taskInfoTypeViewAppearance = instance.taskInfoTypeViewAppearance
		self.chatNavigationBarAppearance = instance.chatNavigationBarAppearance
        self.customNavigationBarAppearance = instance.customNavigationBarAppearance
		self.newRequestsViewAppearance = instance.newRequestsViewAppearance
		self.searchTextFieldAppearance = instance.searchTextFieldAppearance
		self.grabberViewAppearance = instance.grabberViewAppearance
		self.countButtonAppearance = instance.countButtonAppearance
		self.shadowContainerViewAppearance = instance.shadowContainerViewAppearance
		self.сontactPrimeNotificationViewAppearance = instance.сontactPrimeNotificationViewAppearance
        self.customSegmentViewAppearance = instance.customSegmentViewAppearance
		self.expandedCalendarEventViewAppearance = instance.expandedCalendarEventViewAppearance

		self.starsControlAppearance = instance.starsControlAppearance
		self.chipsControlAppearance = instance.chipsControlAppearance
		self.primeTextViewComponentAppearance = instance.primeTextViewComponentAppearance
		self.filledActionButtonAppearance = instance.filledActionButtonAppearance

		self.feedbackViewAppearance = instance.feedbackViewAppearance
		self.feedbackRatingViewAppearance = instance.feedbackRatingViewAppearance
		self.feedbackDetailsViewAppearance = instance.feedbackDetailsViewAppearance
		self.feedbackSuccessViewAppearance = instance.feedbackSuccessViewAppearance
		self.feedbackStarsContainerAppearance = instance.feedbackStarsContainerAppearance
		self.curtainViewAppearance = instance.curtainViewAppearance
        self.unreadCountBadgeAppearance = instance.unreadCountBadgeAppearance

		self.fullImageViewControllerAppearance = instance.fullImageViewControllerAppearance

		Notification.post(.paletteDidChange)
	}

	func appearance<T>() -> T! {
		let mirror = Mirror(reflecting: self)
		return mirror.children.first { $0.value is T }?.value as? T
	}
}
