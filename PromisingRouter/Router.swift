import Foundation

private class URLRef: Equatable {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
}

private func ==(lhs: URLRef, rhs: URLRef) -> Bool {
    return lhs === rhs
}

@objc public class PRRRouter: NSObject {
    private var routings: [PRRRouting]
    private var queue: dispatch_queue_t
    private var pendingURLs: [URLRef]
    
    /**
     Delegate
     */
    public weak var delegate: PRRRouterDelegate?
    
    /**
     Initializer.
     
     @param queue GCD queue on which actions and delegate methods are invoked.
     @remark This class is not thread safe. Make sure all operations for the object are done from queue given to this initializer.
     */
    public init(queue: dispatch_queue_t) {
        self.queue = queue
        
        self.routings = []
        self.pendingURLs = []
    }
    
    /**
     Queue URL to be routed.
     
     @param url URL to be routed
     @param timeout Timeout in seconds, 0 for no timeout
     */
    public func dispatch(url: NSURL, timeout: NSTimeInterval) {
        let ref = URLRef(url: url)
        self.pendingURLs.append(ref)
        self.tryDispatchURLs()
        
        if timeout > 0 {
            weak var wself = self
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC))), self.queue) {
                if let this = wself {
                    if let index = this.pendingURLs.indexOf(ref) {
                        this.pendingURLs.removeAtIndex(index)
                        let params = queryParametersWithURL(url)
                        this.delegate?.routerDidTimeout?(this, url: ref.url, parameters: params)
                    }
                }
            }
        }
    }
    
    /**
     Cancel all pending dispatch.
     */
    public func cancel() {
        self.pendingURLs = []
        self.delegate?.routerDidCancel?(self)
    }

    /**
     Returns new routing with route string.
     */
    public func routingWithRoute(route: String) -> PRRRouting {
        let routing = PRRRouting(router: self, route: route)
        self.routings.append(routing)
        
        return routing
    }
    
    func tryDispatchURLs() {
        dispatch_async(self.queue) {
            let pendingURLs = self.pendingURLs
            self.pendingURLs.removeAll()
            
            for ref in pendingURLs {
                let url = ref.url
                
                let applicableRoutings: [(PRRRouting, [String: String])] = self.routings.flatMap { routing in
                    if let binding = bindParametersFromPath(routing.route, url: url) {
                        return (routing, binding)
                    } else {
                        return nil
                    }
                }
                if let (routing, binding) = applicableRoutings.first {
                    // Route found
                    if let action = routing.action {
                        let queryParameters = queryParametersWithURL(url)
                        
                        let request = PRRRequest(url: url, pathParameters: binding, queryParameters: queryParameters)
                        
                        self.delegate?.routerWillRoute?(self, routing: routing, request: request)
                        let result = action.runActionForRoute(routing, request: request)
                        self.delegate?.routerDidRoute?(self, routing: routing, request: request, result: result)
                    } else {
                        // Enqueue again
                        self.pendingURLs.append(ref)
                    }
                } else {
                    // No route found
                    let params = queryParametersWithURL(url)
                    self.delegate?.routerDidFailToRoute?(self, url: url, parameters: params)
                }
            }
        }
    }
}