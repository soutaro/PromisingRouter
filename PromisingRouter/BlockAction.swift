import Foundation

@objc class PRRBlockAction : NSObject, PRRAction {
    let block: PRRRequest -> PRRResult?
    
    init(block: PRRRequest -> PRRResult?) {
        self.block = block
    }
    
    func runActionForRoute(routing: PRRRouting, request: PRRRequest) -> PRRResult? {
        return self.block(request)
    }
}
