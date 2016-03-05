import XCTest
@testable import PromisingRouter

class RoutingResult : NSObject, PRRResult {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}

class RoutingAction : NSObject, PRRAction {
    let message: String
    
    init(message: String) {
        self.message = message
    }
    
    func runActionForRoute(routing: PRRRouting, request: PRRRequest) -> PRRResult? {
        return RoutingResult(message: self.message)
    }
}

class RoutingTests: XCTestCase, PRRRouterDelegate {
    var queue: dispatch_queue_t!
    var router: PRRRouter!
    var showRouting: PRRRouting!
    var indexRouting: PRRRouting!
    
    var didFailTrace: [NSURL]!
    var didRouteTrace: [(PRRAction, PRRRequest, RoutingResult?)]!
    var didTimeoutTrace: [NSURL]!
    var willRouteTrace: [(PRRAction, PRRRequest)]!
    
    override func setUp() {
        super.setUp()
        
        self.queue = dispatch_queue_create("promisingrouter.test", nil)
        
        self.router = PRRRouter(queue: self.queue)
        self.showRouting = router.routingWithRoute("/people/:id/show")
        self.indexRouting = router.routingWithRoute("/people")
        self.router.delegate = self
        
        self.didFailTrace = []
        self.didRouteTrace = []
        self.didTimeoutTrace = []
        self.willRouteTrace = []
    }
    
    override func tearDown() {
        self.showRouting = nil
        self.indexRouting = nil
        self.router = nil
        self.queue = nil
        
        self.didFailTrace = nil
        self.didRouteTrace = nil
        self.didTimeoutTrace = nil
        self.willRouteTrace = nil
        
        super.tearDown()
    }
    
    func postNotification(name: String) {
        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: self)
        }
    }
    
    func routerDidFailToRoute(router: PRRRouter, url: NSURL) {
        self.didFailTrace.append(url)
        self.postNotification("RouterDidFailToRoute")
    }
    
    func routerDidRoute(router: PRRRouter, action: PRRAction, request: PRRRequest, result: PRRResult?) {
        self.didRouteTrace.append((action, request, result as! RoutingResult?))
        self.postNotification("RouterDidRoute")
    }
    
    func routerDidTimeout(router: PRRRouter, url: NSURL) {
        self.didTimeoutTrace.append(url)
        self.postNotification("RouterDidTimeout")
    }
    
    func routerWillRoute(router: PRRRouter, action: PRRAction, request: PRRRequest) {
        self.willRouteTrace.append((action, request))
        self.postNotification("RouterWillRoute")
    }
    
    func routerDidCancel(router: PRRRouter) {
        self.postNotification("RouterDidCancel")
    }
    
    func testRouting() {
        self.showRouting.action = RoutingAction(message: "show")
        self.indexRouting.action = RoutingAction(message: "index")
        
        self.expectationForNotification("RouterDidRoute", object: self, handler: nil)
        
        dispatch_sync(self.queue) {
            self.router.dispatch(NSURL(string: "app://people/1/show")!, timeout: 0.1)
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        let request = self.didRouteTrace[0].1
        let result = self.didRouteTrace[0].2
        
        XCTAssertEqual(["id": "1"], request.parameters)
        XCTAssertEqual("show", result!.message)
        

        self.expectationForNotification("RouterDidRoute", object: self, handler: nil)
        
        dispatch_sync(self.queue) {
            self.router.dispatch(NSURL(string: "app://people")!, timeout: 0.1)
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        let request2 = self.didRouteTrace[1].1
        let result2 = self.didRouteTrace[1].2
        
        XCTAssertEqual([:], request2.parameters)
        XCTAssertEqual("index", result2!.message)
    }
    
    func testRoutingFailure() {
        self.expectationForNotification("RouterDidFailToRoute", object: self, handler: nil)
        
        dispatch_sync(self.queue) {
            self.router.dispatch(NSURL(string: "app://no/such/route")!, timeout: 0.1)
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testRoutingTimeout() {
        self.expectationForNotification("RouterDidTimeout", object: self, handler: nil)
        
        dispatch_sync(self.queue) {
            self.router.dispatch(NSURL(string: "app://people/1/show")!, timeout: 0.1)
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testRoutingResume() {
        self.expectationForNotification("RouterDidRoute", object: self, handler: nil)
        
        dispatch_sync(self.queue) {
            self.router.dispatch(NSURL(string: "app://people/1/show")!, timeout: 0.5)
        }
        
        let showAction = RoutingAction(message: "show")
        self.showRouting.action = showAction
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testRoutingCancel() {
        self.expectationForNotification("RouterDidCancel", object: self, handler: nil)
        
        dispatch_sync(self.queue) {
            self.router.dispatch(NSURL(string: "app://people/1/show")!, timeout: 0.1)
            self.router.cancel()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        XCTAssert(self.didRouteTrace.isEmpty)
        XCTAssert(self.didTimeoutTrace.isEmpty)
        XCTAssert(self.willRouteTrace.isEmpty)
        XCTAssert(self.didFailTrace.isEmpty)
    }
}
