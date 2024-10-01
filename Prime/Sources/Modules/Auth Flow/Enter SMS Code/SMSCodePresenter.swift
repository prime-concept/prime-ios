import Foundation
import PromiseKit

protocol SMSCodePresenterProtocol {
    func verify(sms code: String)
    func register()
	func resolveLoginProblems()
}

final class SMSCodePresenter: SMSCodePresenterProtocol {
    private enum Constants {
        static let invalidConfirmationKey = "invalid confirmation key"
        static let notFound = 404
		static let serverError = 500
		static let multipleUsersFoundRegex = "^found \\w{1,} customers with phone number"
    }

    private let endpoint: AuthEndpoint
    private let authService: LocalAuthService
    private let analyticsReporter: AnalyticsReportingServiceProtocol

    private let phone: String
    private var user: Profile?
	private let smsRequestsLimit: Int? = nil
    private var verificationAttemptsTaken = 0
    private var onLoginProblems: () -> Void

    weak var controller: SMSCodeViewProtocol?

    init(
        endpoint: AuthEndpoint,
        phone: String,
        authService: LocalAuthService,
        analyticsReporter: AnalyticsReportingServiceProtocol,
        onLoginProblems: @escaping () -> Void
    ) {
        self.endpoint = endpoint
        self.phone = phone
        self.authService = authService
        self.analyticsReporter = analyticsReporter
        self.onLoginProblems = onLoginProblems
    }

	 func verify(sms code: String) {
		  if let limit = self.smsRequestsLimit,
			 self.verificationAttemptsTaken >= limit {
			   self.alertSMSRequestsExceeded()
			   return
		  }

		  self.controller?.view.showLoadingIndicator()
		  self.controller?.updateUserInteraction(isEnabled: false)

		  DispatchQueue.global(qos: .userInitiated).promise {
			   self.endpoint.verify(phone: self.phone, key: code).promise
		  }.then { [weak self] user -> Promise<EmptyResponse> in
			   if let self = self {
					self.user = user
					return self.check(phone: self.phone)
			   }

			   let userInfo = [NSLocalizedDescriptionKey: "\(Self.self) is deinitialized"]
			   return Promise(error: NSError(domain: "Verification", code: 0, userInfo: userInfo))
		  }.done { [weak self] _ in
			   NotificationCenter.default.post(
					name: .smsCodeVerified,
					object: nil,
					userInfo: ["phone": self?.phone as Any, "user": self?.user as Any]
			   )
		  }.ensure { [weak self] in
			   self?.controller?.view.hideLoadingIndicator()
			   self?.controller?.updateUserInteraction(isEnabled: true)
		  }.catch { error in
			   AnalyticsReportingService
					.shared.log(
						 name: "[ERROR] \(Swift.type(of: self)) SMS verification failed",
						 parameters: error.asDictionary
					)

			   self.process(error)
			   DebugUtils.shared.alert(sender: self, "ERROR WHILE VERIFY: \(error.localizedDescription)")
		  }
	 }

    func register() {
        self.analyticsReporter.requestedSMSCode()
        self.controller?.updateUserInteraction(isEnabled: false)
        DispatchQueue.global(qos: .userInitiated).promise {
            self.endpoint.register(phone: self.phone).promise
        }.done { [weak self] _ in
            self?.verificationAttemptsTaken = 0
            self?.controller?.activateCodeTimer()
        }.catch { error in
		    AnalyticsReportingService
				  .shared.log(
					name: "[ERROR] \(Swift.type(of: self)) SMS Request failed",
					parameters: error.asDictionary
				  )
		    AlertPresenter.alertCommonError(error)
            DebugUtils.shared.alert(sender: self, "ERROR WHILE REQUESTING SMS: \(error.localizedDescription)")
        }.finally { [weak self] in
            self?.controller?.updateUserInteraction(isEnabled: true)
        }
    }

	func resolveLoginProblems() {
		self.onLoginProblems()
	}

    // MARK: - Helpers

	private func alertSMSRequestsExceeded() {
		let title = "auth.limitExceeded".localized
		let with = "auth.requestCodeAgain".localized

		self.controller?.alert(title: title, with: with) { _ in
			self.controller?.activateSendCode()
		}
	}

    private func check(phone number: String) -> Promise<EmptyResponse> {
        DispatchQueue.global(qos: .userInitiated).promise {
            self.endpoint.check(phone: self.phone).promise
        }
    }

    private func process(_ error: Error) {
		let description = error.descriptionLowercased

		if description.contains(Constants.invalidConfirmationKey) {
            self.verificationAttemptsTaken += 1
            self.controller?.showWrongCodeState()
			return
        }

		 if description.first(match: "customer with phone number .+? not found") != nil {
			  self.onLoginProblems()
			  return
		 }

		let isMultipleUsersError = description.first(match: Constants.multipleUsersFoundRegex) != nil

		if isMultipleUsersError {
			 self.alertMultipleUsersError()
			return
		}

		 AlertPresenter.alertCommonError()
    }

	 private func alertMultipleUsersError() {
		  AlertPresenter.alert(
			  message: "form.server.error.multiple.users".localized,
			  actionTitle: "form.cancel".localized,
			  cancelTitle: "contact.prime.call".localized,
			  onAction: {
				  self.controller?.navigationController?.popViewController(animated: false)
			  },
			  onCancel: {
				  self.controller?.navigationController?.popViewController(animated: false)
				  PrimeContacts.call()
			  }
		  )
	 }
}
