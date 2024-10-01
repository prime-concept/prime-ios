struct WalletCardDownloadInfo: Decodable {
    let url: String
    let agent: String
    let downloadAllowed: Bool
}
