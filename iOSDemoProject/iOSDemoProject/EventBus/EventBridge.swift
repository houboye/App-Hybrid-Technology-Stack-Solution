import Foundation

protocol EventBridgeAdapter: AnyObject {
    var stackId: StackIdentifier { get }
    func send(message: EventMessage)
}
