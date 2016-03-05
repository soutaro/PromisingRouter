import Foundation

/**
 Protocol for delegate.
 All methods are optional so that you can let your delegate be without some methods it is not interested in.
*/
@objc public protocol PRRRouterDelegate {
    optional func routerWillRoute(router: PRRRouter, action: PRRAction, request: PRRRequest)
    optional func routerDidRoute(router: PRRRouter, action: PRRAction, request: PRRRequest, result: PRRResult?)
    optional func routerDidTimeout(router: PRRRouter, url: NSURL)
    optional func routerDidFailToRoute(router: PRRRouter, url: NSURL)
    optional func routerDidCancel(router: PRRRouter)
}

/**
 Protocol for routing action.
 Your action object should conform to this protocol.
*/
@objc public protocol PRRAction: NSObjectProtocol {
    func runActionForRoute(routing: PRRRouting, request: PRRRequest) -> PRRResult?
}

/**
 Protocol for routing result.
 This protocol does not specify any method and is just a mark to your class is a result.
*/
@objc public protocol PRRResult: NSObjectProtocol {
}

