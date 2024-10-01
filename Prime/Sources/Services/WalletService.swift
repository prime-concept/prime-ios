import PassKit
import PromiseKit
import Alamofire

protocol WalletServiceProtocol {
    func getPKPass() -> Promise<PKPass>
}

final class WalletService: WalletServiceProtocol {
    private let endpoint = WalletEndpoint()

    func getPKPass() -> Promise<PKPass> {
        DispatchQueue.global(qos: .userInitiated).promise {
            self.endpoint.getWalletCardDownloadInfo().promise
        }.then { info -> Promise<Data> in
            guard let url = URL(string: info.url) else {
				throw Endpoint.Error(.decodeFailed, details: "Invalid URL")
            }
            return self.endpoint.loadPKPassData(url: url)
        }.then { pkPassData -> Promise<PKPass> in
            guard let pass = try? PKPass(data: pkPassData) else {
                throw Endpoint.Error(.decodeFailed, details: "Invalid PKPass Data")
            }
            return Promise.value(pass)
        }
    }
}
