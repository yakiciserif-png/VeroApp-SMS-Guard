import IdentityLookup

/// FAZ 4: Apple IdentityLookup (`ILMessageFilterExtension`) real-time SMS/MMS
/// interceptor synchronized with `TrustFilterEngine.shared` via App Group
/// `group.com.trustlens.filter`.
///
/// Runs 100% offline inside the iOS sandbox in < 5 ms without network calls.
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        let response = ILMessageFilterQueryResponse()

        // Load latest rules, whitelist, and sensitivity thresholds from App Group
        TrustFilterEngine.shared.loadFromAppGroup()

        let messageBody = queryRequest.messageBody ?? ""
        let sender = queryRequest.sender ?? ""

        let decision = TrustFilterEngine.shared.classify(messageBody, sender: sender)

        switch decision.category {
        case "spam":
            if decision.subCategory == "promotion" {
                if #available(iOS 14.0, *) {
                    response.action = .promotion
                    response.subAction = .promotionOffers
                } else {
                    response.action = .filter
                }
            } else {
                response.action = .junk
                if #available(iOS 14.0, *) {
                    response.subAction = .junk
                }
            }
        case "transaction":
            if #available(iOS 14.0, *) {
                response.action = .transaction
                response.subAction = decision.subCategory == "bank_transaction"
                    ? .transactionalFinance
                    : .transactionalOthers
            } else {
                response.action = .allow
            }
        default:
            // Normal / Whitelist / "Hakan Abi & Dükkan" Personal Conversation -> Allow
            response.action = .allow
        }

        completion(response)
    }
}
