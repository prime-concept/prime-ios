import UIKit
import ChatSDK

protocol RequestCreationControllerProviding {
    var viewController: UIViewController { get }
}

final class RequestCreationAssembly {
    private let canUseChat: Bool
	private let profileService: ProfileServiceProtocol

    init(canUseChat: Bool,
		 profileService: ProfileServiceProtocol) {
        self.canUseChat = canUseChat
		self.profileService = profileService
    }

    func make() -> RequestCreationControllerProviding {
        if self.canUseChat {
            return self.makeControllerWithChat()
        } else {
            return self.makeControllerWithoutChat()
        }
    }

    // MARK: - Private

    private func makeControllerWithoutChat() -> UIViewController {
        let presenter = RequestCreationPresenter(taskPersistenceService: TaskPersistenceService())
        let controller = RequestCreationViewController(presenter: presenter)
        presenter.controller = controller

        let containerController = RequestCreationContainerViewController()

        let navigationController = NavigationController(rootViewController: controller)
        navigationController.navigationBar.applyStyle()

        containerController.displayChild(viewController: navigationController)

        return containerController
    }

    private func makeControllerWithChat() -> ChatAssembly.ChatChannelContainer {
        let presenter = RequestCreationPresenter(taskPersistenceService: TaskPersistenceService())
        let controller = RequestCreationViewController(presenter: presenter)
        presenter.controller = controller

        let containerController = RequestCreationContainerViewController()
        let navigationController = NavigationController(rootViewController: controller)
        navigationController.navigationBar.applyStyle()

        containerController.displayChild(viewController: navigationController)

        let userID = LocalAuthService.shared.user?.username ?? ""

        let params = ChatAssembly.ChatParameters(
            chatToken: LocalAuthService.shared.token?.accessToken ?? "",
            channelID: "N\(userID)",
            channelName: "chat".localized,
            clientID: "C\(userID)"
        )

        let messengersView = ChatAssistantMessengersView()

        var dismissKeyboardClosure: (() -> Void)?
        var retryFailedSending: ((MessagesSendingStatus) -> Void)?

        let isKeyboardPresented = BoolReference()
        let messagesSendingStatus = MessagesSendingStatus()

        let presentStatusAlert: (MessagesSendingStatus, @escaping () -> Void) -> Void = { [weak containerController]
            sendingStatus, onSuccess in
            let isSuccess = sendingStatus.failed.isEmpty

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if isSuccess {
                    HUD.show(mode: .success, timeout: 0.5, onRemove: onSuccess)
                } else {
                    guard let strongContainerController = containerController else {
                        return
                    }

                    let controller = UIAlertController(
                        title: "common.error.2".localized,
                        message: "createTask.could.not.send.message".localized
                        + "createTask.check.connection".localized,
                        preferredStyle: .alert
                    )
                    controller.addAction(
                        .init(
                            title: "common.retry".localized,
                            style: .default,
                            handler: { _ in retryFailedSending?(sendingStatus) }
                        )
                    )
                    controller.addAction(.init(title: "common.continue".localized, style: .cancel))

                    ModalRouter(source: strongContainerController, destination: controller).route()
                }
            }
        }

        let onTextViewEditingStatusUpdate: (Bool) -> Void = { [weak containerController, messengersView] isBegin in
            isKeyboardPresented.value = isBegin

            if isBegin {
                containerController?.presentBlurredOverlayIfNeeded(messengersView: messengersView) {
                    dismissKeyboardClosure?()
                }
            } else {
                containerController?.dismissBlurredOverlayIfNeeded(messengersView: messengersView)
                dismissKeyboardClosure?()
            }
        }

        let onMessageSend: (String, Bool) -> Void = { [weak containerController] uid, successful in
            dismissKeyboardClosure?()

            messagesSendingStatus.inProgress.remove(uid)
            if !successful {
                messagesSendingStatus.failed.insert(uid)
            }

            guard messagesSendingStatus.inProgress.isEmpty else {
                return
            }

            presentStatusAlert(messagesSendingStatus) {
                guard let strongContainerController = containerController else {
                    return
                }

				let assistant = self.profileService.profile?.assistant ??
								Assistant(firstName: "Default", lastName: "Assistant")

                let assistantChatModule = ChatAssembly.makeDefault(
                    with: params,
                    presentationViewController: strongContainerController,
                    assistant: assistant
                )
                strongContainerController.present(assistantChatModule.viewController, animated: true)
            }
        }

        let onAttachementsStatusUpdate: (Int) -> Void = { [weak containerController, messengersView] totalCount in
            DispatchQueue.main.async {
                if totalCount == 0 {
                    if !isKeyboardPresented.value {
                        containerController?.dismissBlurredOverlayIfNeeded(messengersView: messengersView)
                    } else {
                        dismissKeyboardClosure?()
                    }
                }
            }
        }

        let onMessageSending: (String) -> Void = { uid in
            if messagesSendingStatus.inProgress.isEmpty {
                HUD.show(mode: .spinner)
            }

            messagesSendingStatus.inProgress.insert(uid)
        }

        let chatContainer = ChatAssembly.makeRequestsCustom(
            with: params,
            presentationViewController: containerController,
            chatContentViewController: containerController,
            onTextViewEditingStatusUpdate: onTextViewEditingStatusUpdate,
            onMessageSend: onMessageSend,
            onMessageSending: onMessageSending,
            onAttachementsStatusUpdate: onAttachementsStatusUpdate
        )

        dismissKeyboardClosure = { [weak controller = chatContainer.viewController] in
            controller?.view.endEditing(true)
        }

        retryFailedSending = { [weak channel = chatContainer.channel] sendingStatus in
            sendingStatus.failed.forEach { uid in
                channel?.retryFailedMessage(with: uid)
            }
        }

        chatContainer.viewController.view.addSubview(messengersView)
        messengersView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(containerController.view)
        }

        return chatContainer
    }

    private final class MessagesSendingStatus {
        var inProgress = Set<String>()
        var failed = Set<String>()
    }

    private final class BoolReference {
        var value = false
    }
}

// MARK: - RequestCreationControllerProviding conforming

extension UIViewController: RequestCreationControllerProviding {
    var viewController: UIViewController { self }
}

extension ChatAssembly.ChatChannelContainer: RequestCreationControllerProviding { }
