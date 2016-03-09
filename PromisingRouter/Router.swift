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
    private var pendingRequests: [(PRRRouting, URLRef, pathParameters: [String: String])]
    
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
        self.pendingRequests = []
    }
    
    /**
     Queue URL to be routed.
     
     @param url URL to be routed
     @param timeout Timeout in seconds, 0 for no timeout
     @return true if corresponding routing found, false if no routing found
     */
    public func dispatch(url: NSURL, timeout: NSTimeInterval) -> Bool {
        let ref = URLRef(url: url)
        if let (routing, params) = self.resolveRouting(url) {
            self.pendingRequests.append((routing, ref, params))
            self.tryDispatchURLs()

            if timeout > 0 {
                weak var wself = self
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC))), self.queue) {
                    wself?.timeoutForURLRef(ref)
                }
            }
            
            return true
        } else {
            let params = queryParametersWithURL(url)
            self.delegate?.routerDidFailToRoute?(self, url: url, parameters: params)
            
            return false
        }
    }
    
    /**
     Cancel all pending dispatch.
     */
    public func cancel() {
        self.pendingRequests = []
        self.delegate?.routerDidCancel?(self)
    }

    /**
     Returns new routing with route string.
     */
    public func routingWithRoute(route: NSURL) -> PRRRouting {
        let routing = PRRRouting(router: self, route: route)
        self.routings.append(routing)
        
        return routing
    }
    
    func resolveRouting(url: NSURL) -> (PRRRouting, [String: String])? {
        let applicableRoutings: [(PRRRouting, [String: String])] = self.routings.flatMap { routing in
            if let binding = bindParametersFromPath(routing.route, url: url) {
                return (routing, binding)
            } else {
                return nil
            }
        }
        
        return applicableRoutings.first
    }
    
    private func timeoutForURLRef(ref: URLRef) {
        if let index = self.pendingRequests.indexOf({ $0.1 == ref }) {
            let tuple = self.pendingRequests[index]
            self.pendingRequests.removeAtIndex(index)
            
            let ref = tuple.1
            let params = queryParametersWithURL(ref.url)
            self.delegate?.routerDidTimeout?(self, url: ref.url, parameters: params)
        }
    }
    
    func tryDispatchURLs() {
        dispatch_async(self.queue) {
            let pendingRequests = self.pendingRequests
            self.pendingRequests.removeAll()
            
            for (routing, ref, pathParams) in pendingRequests {
                let url = ref.url
                
                // Route found
                if let action = routing.action {
                    let queryParameters = queryParametersWithURL(url)
                    
                    let request = PRRRequest(url: url, pathParameters: pathParams, queryParameters: queryParameters)
                    
                    self.delegate?.routerWillRoute?(self, routing: routing, request: request)
                    let result = action.runActionForRoute(routing, request: request)
                    self.delegate?.routerDidRoute?(self, routing: routing, request: request, result: result)
                } else {
                    // Enqueue again
                    self.pendingRequests.append((routing, ref, pathParams))
                }
            }
        }
    }
}