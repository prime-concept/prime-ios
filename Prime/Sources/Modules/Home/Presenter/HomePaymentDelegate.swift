import SafariServices

final class HomePaymentDelegate: NSObject, SFSafariViewControllerDelegate {
    
    private var onFinishClosure: () -> Void
    
    init(onFinishClosure: @escaping () -> Void) {
        self.onFinishClosure = onFinishClosure
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        onFinishClosure()
    }
}
