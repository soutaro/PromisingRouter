import Foundation

@objc public class PRRBlockAction : NSObject, PRRAction {
    public let block: PRRRequest -> PRRResult?
    
    public init(block: PRRRequest -> PRRResult?) {
        self.block = block
    }
    
    public func runActionForRoute(routing: PRRRouting, request: PRRRequest) -> PRRResult? {
        return self.block(request)
    }
}
