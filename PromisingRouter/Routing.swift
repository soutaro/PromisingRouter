import Foundation

@objc public class PRRRouting: NSObject {
    /**
     Route pattern string for this routing entry.
     */
    public let route: String
    
    var _action: PRRAction?
    
    /**
     Router associated with this routing.
     */
    public unowned let router: PRRRouter
    
    init(router: PRRRouter, route: String) {
        self.router = router
        self.route = route
    }
    
    /**
     Set action be nil, when current action is given one to this method.
     If different action is specified, this method does nothing.
     */
    public func unsetAction(action: PRRAction) {
        if action.isEqual(self.action) {
            self.action = nil
        }
    }
    
    /**
     Action associated with this routing.
     */
    public weak var action: PRRAction? {
        get {
            return _action
        }
        
        set(action) {
            _action = action
            if action != nil {
                self.router.tryDispatchURLs()
            }
        }
    }
}