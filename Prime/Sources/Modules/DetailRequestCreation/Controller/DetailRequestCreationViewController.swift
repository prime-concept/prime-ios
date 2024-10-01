import IQKeyboardManagerSwift
import UIKit

protocol DetailRequestCreationViewProtocol: AnyObject {
    func set(viewModels: [TaskCreationFieldViewModel])
    func dismiss()
	func show(error: String)
	func showLoading()
	func hideLoading()
}

final class DetailRequestCreationViewController: UIViewController, DetailRequestCreationViewProtocol {
    var completion: ((Int?) -> Void)?
    private lazy var detailRequestCreationView = self.view as? DetailRequestCreationView

    private lazy var selectionPresentationManager = FloatingControllerPresentationManager(
        context: .itemSelection,
        sourceViewController: self
    )

    private let presenter: DetailRequestCreationPresenter

    private var data: [(name: String, view: TaskFieldValueInputProtocol)] = []
    private var viewModels: [TaskCreationFieldViewModel] = []

    init(presenter: DetailRequestCreationPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        self.view = DetailRequestCreationView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.detailRequestCreationView?.onBuyButton = { [weak self] in
			self.some { (self) in
                self.view.endEditing(true)
				self.dismiss()
			}
        }
        self.detailRequestCreationView?.onAssistantButton = { [weak self] in
			self.some { (self) in
                self.view.endEditing(true)
				self.presenter.submitTask { [weak self] taskId in
					self?.completion?(taskId)
				}
			}
        }
        self.presenter.didLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        IQKeyboardManager.shared.enable = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        IQKeyboardManager.shared.enable = false
    }

	// swiftlint:disable switch_case_alignment
	private func makeView(from viewModel: TaskCreationFieldViewModel) -> UIView? {
		switch viewModel.form.type {
			case .combobox, .dictionary, .dictionaryManyToMany:
				let view = DetailRequestCreationSelectionView()
				view.setup(with: viewModel)

				view.addTapHandler { [weak self] in
					self?.openSelection(for: viewModel)
				}

				self.data.append((viewModel.input.fieldName, view))

				return view
			case .separator:
				let view = DetailRequestCreationSeparatorView()
				view.setup(with: viewModel)

				self.data.append((viewModel.input.fieldName, view))

				return view
            case .text, .childAges:
				let view = DetailRequestCreationTextField()
				view.setup(with: viewModel)

				self.data.append((viewModel.input.fieldName, view))

				view.onTextEdit = { [weak viewModel] value in
					viewModel?.input.oldValue = viewModel?.input.newValue
					viewModel?.input.newValue = value ?? ""
				}

				return view
			case .dateTime, .date:
				let view = DetailRequestCreationTextField(type: .date)
				view.setup(with: viewModel)

				self.data.append((viewModel.input.fieldName, view))

				view.onDateSelected = { [weak viewModel] dateString in
					viewModel?.input.newValue = dateString
					viewModel?.input.dtValue = dateString
				}

				return view
			case .dateTimeZone:
				let view = DetailRequestCreationTimeWithTimeZoneView()
				view.setup(with: viewModel)

				view.onDateSelected = { [weak viewModel] dateString in
					viewModel?.input.dtValue = dateString
				}

				view.onTimeZoneSelected = { [weak viewModel] timeZone in
					viewModel?.input.newValue = timeZone.abbreviation() ?? ""
					viewModel?.input.timezoneOffset = timeZone.secondsFromGMT() / 60
				}

				self.data.append((viewModel.input.fieldName, view))

				return view

			case .textWithoutLabel:
				let view = DetailRequestCreationTextField(type: .text(titleHidden: true))
				view.setup(with: viewModel)

				self.data.append((viewModel.input.fieldName, view))

				view.onTextEdit = { [weak viewModel] value in
					viewModel?.input.oldValue = viewModel?.input.newValue
					viewModel?.input.newValue = value ?? ""
				}

				return view
			case .numberText:
				let view = DetailRequestCreationTextField(type: .number)
				view.setup(with: viewModel)

				self.data.append((viewModel.input.fieldName, view))

				view.onTextEdit = { [weak viewModel] value in
					viewModel?.input.oldValue = viewModel?.input.newValue
					viewModel?.input.newValue = value ?? ""
					viewModel?.input.intValue = Int(value ?? "")
				}

				return view
			case .checkBoxLineLabel:
				let view = DetailRequestCreationCheckboxView()
				view.setup(with: viewModel)

				self.data.append((viewModel.input.fieldName, view))

				view.onSwitchAction = { [weak self] boolValue in
					guard let strongSelf = self else {
						return
					}
					let value = boolValue ? 1 : 0
					viewModel.input.intValue = boolValue ? 1 : 0
					viewModel.input.dictionaryOptions = ["\(value)"]
					strongSelf.presenter.didUpdateField(viewModel: viewModel)
				}

				return view
			case .textArea:
				let view = DetailRequestCreationTextView()
				view.setup(with: viewModel)

				view.onTextEdit = { [weak viewModel] value in
					viewModel?.input.oldValue = viewModel?.input.newValue
					viewModel?.input.newValue = value ?? ""
				}

				self.data.append((viewModel.input.fieldName, view))

				return view
			case .airport:
				let view = DetailRequestCreationSelectionView()
				view.setup(with: viewModel)

				view.addTapHandler { [weak self] in
					self?.openAirportSelection(for: viewModel)
				}

				self.data.append((viewModel.input.fieldName, view))

				return view
			case .city:
				let view = DetailRequestCreationSelectionView()
				view.setup(with: viewModel)

				view.addTapHandler { [weak self] in
					self?.openCitySelection(for: viewModel)
				}

				self.data.append((viewModel.input.fieldName, view))

				return view
			case .fieldNotice:
				let view = DetailRequestCreationFieldNoticeView()
				view.setup(with: viewModel)

				return view
			case .partner:
				let view = DetailRequestCreationSelectionView()
				view.setup(with: viewModel)

				self.data.append((viewModel.input.fieldName, view))

				view.addTapHandler { [weak self] in
					self?.openPartnerSelection(for: viewModel)
				}

				return view
			default:
				let view = DetailRequestCreationUnsupportedView()
				view.setup(with: viewModel)
				self.data.append((viewModel.input.fieldName, view))

				return view
		}
	}
	// swiftlint:enable switch_case_alignment

    private func openAirportSelection(for field: TaskCreationFieldViewModel) {
        self.view.endEditing(true)

        let assembly = AirportListAssembly(leg: .departure) { airport in
			DebugUtils.shared.log(sender: self, airport)
			return true
        }
        let controller = assembly.make()
		self.presentSelection(with: controller, scrollView: assembly.scrollView)
    }

	private func openCitySelection(for field: TaskCreationFieldViewModel) {
		self.view.endEditing(true)

		let assembly = AnyCitySelectionAssembly(
            selectedCityId: field.input.intValue,
			onSelect: { [weak presenter] city in
				field.input.newValue = city.name
				field.input.intValue = city.id
				presenter?.didUpdateField(viewModel: field)
			}
		)
		let controller = assembly.make()
		self.presentSelection(with: controller, scrollView: assembly.scrollView)
	}

	private func openPartnerSelection(for field: TaskCreationFieldViewModel) {
		self.view.endEditing(true)

		let assembly = PartnerSelectionAssembly(
			partnerTypeId: field.form.partnerTypeId,
            selectedPartnerId: field.input.intValue,
			onSelect: { [weak presenter] partner in
				field.input.newValue = partner.name
				field.input.intValue = partner.id
				presenter?.didUpdateField(viewModel: field)
			}
		)

		let controller = assembly.make()
		self.presentSelection(with: controller, scrollView: assembly.scrollView)
	}

    private func openSelection(for field: TaskCreationFieldViewModel) {
        self.view.endEditing(true)

        if field.form.options.isEmpty {
            return
        }

        let assembly = SelectionAssembly(
            data: field,
            allowMultipleSelection: field.form.type == TaskCreationFormType.dictionaryManyToMany,
            onSelect: { [weak presenter] model in
                presenter?.didUpdateField(viewModel: model)
            }
        )

        let controller = assembly.make()
		self.presentSelection(with: controller, scrollView: assembly.scrollView)
    }

    func set(viewModels: [TaskCreationFieldViewModel]) {
        self.viewModels = viewModels
        var formViews = [UIView]()

        viewModels.forEach { viewModel in
            if viewModel.isVisible, let view = self.makeView(from: viewModel) {
                formViews.append(view)
            }
        }

        self.data = []
        self.detailRequestCreationView?.set(views: formViews)
    }

	func dismiss() {
		self.dismiss(animated: true, completion: nil)
	}

	func showLoading() {
		self.detailRequestCreationView?.showLoading()
	}

	func hideLoading() {
		self.detailRequestCreationView?.hideLoading()
	}

	func show(error: String) {
		// TODO: сделать ошибку, когда появятся в макете
		HUD.find(on: self.view)?.remove()
		
		let alert = UIAlertController(title: nil, message: error, preferredStyle: .alert)
        alert.addAction(.init(title: "common.ok".localized.uppercased(), style: .default, handler: nil))

		self.present(alert, animated: true)
	}

	private func presentSelection(with controller: UIViewController, scrollView: UIScrollView?) {
		self.selectionPresentationManager.contentViewController = controller
		self.selectionPresentationManager.track(scrollView: scrollView)
		self.selectionPresentationManager.present()
	}
}
