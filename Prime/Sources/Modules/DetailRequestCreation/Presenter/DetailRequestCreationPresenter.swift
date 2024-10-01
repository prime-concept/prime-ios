import Foundation

protocol DetailRequestCreationPresenterProtocol {
    func didLoad()
    func didUpdateField(viewModel: TaskCreationFieldViewModel)
	func submitTask(completion: ((Int?) -> Void)?)
}

final class DetailRequestCreationPresenter: DetailRequestCreationPresenterProtocol {
    private let typeID: Int
    private let graphQLEndpoint: GraphQLEndpointProtocol

    private let maskVisibilityService: MaskFieldVisibilityServiceProtocol
    private let localAuthService: LocalAuthServiceProtocol

    private var fieldViewModels: [TaskCreationFieldViewModel] = []
    private var formVisibilityMask = 0

    weak var controller: DetailRequestCreationViewProtocol?

    init(
        typeID: Int,
        graphQLEndpoint: GraphQLEndpointProtocol,
        maskVisibilityService: MaskFieldVisibilityServiceProtocol = MaskFieldVisibilityService(),
        localAuthService: LocalAuthServiceProtocol = LocalAuthService()
    ) {
        self.typeID = typeID
        self.graphQLEndpoint = graphQLEndpoint
        self.maskVisibilityService = maskVisibilityService
        self.localAuthService = localAuthService
    }

    func didLoad() {
        self.fetchForm()
    }

    private func fetchForm() {
		let language = Locale.primeLanguageCode

        let variables = [
            "lang": AnyEncodable(value: language),
            "formId": AnyEncodable(value: self.typeID)
        ]

        self.graphQLEndpoint.request(
            query: GraphQLConstants.fetchTaskTypeForm,
            variables: variables
        ).promise.done { [weak self] (response: TaskCreationFormResponse) in
            guard let strongSelf = self else {
                return
            }

            let fields = response.data.taskTypeForm.field

            let fieldViewModels = fields.enumerated().map {
                TaskCreationFieldViewModel(
                    form: $1,
                    input: TaskFieldValueInput (form: $1),
                    isVisible: strongSelf.maskVisibilityService.isFieldVisible(
                        formVisibilityMask: strongSelf.formVisibilityMask,
                        fieldVisibilityMask: $1.visibility.first
                    )
                )
            }
            self?.fieldViewModels = fieldViewModels

            self?.updateFormVisibility()
            self?.updateFieldsVisibility()

            strongSelf.controller?.set(viewModels: fieldViewModels)
        }.catch { [weak self] error in
			AlertPresenter.alertCommonError(error)
            DebugUtils.shared.alert(sender: self, "ERROR WHILE FETCHING FORM: \(error.localizedDescription)")
        }
    }

    func submitTask(completion: ((Int?) -> Void)? = nil) {
        let filteredViewModels = self.fieldViewModels.filter { !$0.form.allowBlank }
        // swiftlint:disable line_length
        var isFormValid = true
        filteredViewModels
            .filter(\.isVisible)
            .forEach {
                let isValid = !($0.input.newValue.isEmpty && $0.input.dictionaryOptions.isEmpty)
				$0.onValidate?(isValid, nil)
                isFormValid = isFormValid && isValid
            }

        guard isFormValid else {
			self.controller?.show(error: Localization.localize("createTask.form.error.validation.local"))
            return
        }

        let taskRequest = TaskCreateModifyRequest(
            taskTypeId: typeID,
            fieldValues: self.fieldViewModels.map { $0.input }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let taskRequestJSONData = try? encoder.encode(taskRequest),
            let taskRequestJSON = String(data: taskRequestJSONData, encoding: .utf8) {
            DebugUtils.shared.log(sender: self, "\n\n [DETAIL REQUEST PRESENTER] taskRequest json \(taskRequestJSON)")
        }

        let variables = [
            "customerId": AnyEncodable(value: localAuthService.user?.username),
            "taskRequest": AnyEncodable(value: taskRequest)
        ]

		self.controller?.showLoading()

        self.graphQLEndpoint.request(
            query: GraphQLConstants.saveTask,
            variables: variables
        ).promise.done { (response: SaveTaskResponse) in
            guard let taskId = response.taskId else {
				guard let errors = response.data.customer.task.saveTask.errors,
					  self.highlightInvalidFields(error: errors) else {
					throw SaveTaskError.unknownError
				}
				self.controller?.hideLoading()
				self.controller?.show(error: Localization.localize("createTask.form.error.validation.server"))
				return
            }
			NotificationCenter.default.post(
				name: .tasksUpdateRequested,
				object: nil,
				userInfo: ["taskId": taskId]
			)
			completion?(taskId)
			DebugUtils.shared.log(sender: self, "task created \(taskId)")
        }.catch { [weak self] error in
			self?.controller?.hideLoading()
			self?.controller?.show(error: Localization.localize("createTask.form.error.unknown"))
            DebugUtils.shared.alert(sender: self, "ERROR WHILE SAVING TASK: \(error.localizedDescription)")
        }
    }

	private func highlightInvalidFields(error: String) -> Bool {
		let fieldIds = error.replacingOccurrences(
				of: "\\[|\\]",
				with: "",
				options: .regularExpression
			)
			.split(separator: ",").compactMap {
				String($0).split(separator: ";")
				.map(String.init(_:))
				.first
		}

		if fieldIds.isEmpty {
			return false
		}

		self.fieldViewModels
			.filter { fieldIds.contains($0.input.fieldName) }
			.forEach { field in
				field.onValidate?(false, "createTask.form.invalidValue".localized)
			}

		return true
	}
	
    func didUpdateField(viewModel: TaskCreationFieldViewModel) {
        self.updateFormVisibility(bySelecting: viewModel)
        self.updateFieldsVisibility()
        DebugUtils.shared.log(sender: self, "visibility changed -> \(fieldViewModels.map { "\($0.form.name) \($0.isVisible)" })")
        self.controller?.set(viewModels: fieldViewModels)
    }

    private func updateFormVisibility(bySelecting viewModel: TaskCreationFieldViewModel? = nil) {
        var formMask = self.formVisibilityMask
        var viewModels = fieldViewModels
        if let viewModel = viewModel {
            viewModels = [viewModel]
        }
        for viewModel in viewModels {
            let selectedOptions = viewModel.form.options.filter({ viewModel.input.dictionaryOptions.contains($0.value) })
            for option in selectedOptions {
                formMask = self.maskVisibilityService.getChangedFormVisibilityMask(
                    formVisibilityMask: formMask,
                    visibilityClear: option.visibilityClear,
                    visibilitySet: option.visibilitySet
                )
            }
        }
        self.formVisibilityMask = formMask
    }

    private func updateFieldsVisibility() {
        for fieldViewModel in fieldViewModels {
            fieldViewModel.isVisible = self.maskVisibilityService.isFieldVisible(
                formVisibilityMask: self.formVisibilityMask,
                fieldVisibilityMask: fieldViewModel.form.visibility.first
            )
        }
    }
}
