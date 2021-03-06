import XCTest
@testable import PromisingRouter

class BindingTests: XCTestCase {
    func testQueryParametersWithURL() {
        XCTAssertEqual([:], queryParametersWithURL(NSURL(string: "app://path/to/resource")!))
        XCTAssertEqual(["query1": "value1", "query2": "バリュー"], queryParametersWithURL(NSURL(string: "app://localhost/path/to/resource?query1=value1&query2=%E3%83%90%E3%83%AA%E3%83%A5%E3%83%BC")!))
    }
    
    func testBindParametersFromPath() {
        XCTAssertEqual([:], bindParametersFromPath(NSURL(string: "app://localhost/welcome")!, url: NSURL(string: "app://localhost/welcome")!)!)
        XCTAssertEqual(["id": "123"], bindParametersFromPath(NSURL(string: "app://localhost/people/:id")!, url: NSURL(string: "app://localhost/people/123")!) ?? [:])
        XCTAssertEqual(["id": "123"], bindParametersFromPath(NSURL(string: "app://localhost/people/:id")!, url: NSURL(string: "app://localhost/people/123/")!) ?? [:])
        XCTAssertEqual(["id": "123"], bindParametersFromPath(NSURL(string: "app://localhost/people/:id/")!, url: NSURL(string: "app://localhost/people/123/")!) ?? [:])
        XCTAssertEqual(["id": "123", "action": "show"], bindParametersFromPath(NSURL(string: "app://localhost/people/:id/:action")!, url: NSURL(string: "app://localhost/people/123/show")!) ?? [:])
        XCTAssertEqual(["id": "123"], bindParametersFromPath(NSURL(string: "app://localhost/people/:id/show")!, url: NSURL(string: "app://localhost/people/123/show")!) ?? [:])
        XCTAssertEqual(["name": "山田太郎"], bindParametersFromPath(NSURL(string: "app://localhost/people/:name")!, url: NSURL(string: "app://localhost/people/%E5%B1%B1%E7%94%B0%E5%A4%AA%E9%83%8E")!) ?? [:])
        
        XCTAssertNil(bindParametersFromPath(NSURL(string: "app://localhost/people/:id")!, url: NSURL(string: "app://localhost/person/123")!))
        XCTAssertNil(bindParametersFromPath(NSURL(string: "app://localhost/people/:id/show")!, url: NSURL(string: "app://localhost/people/123/delete")!))
    }
    
    func testBindingFromHost() {
        XCTAssertEqual([:], bindParametersFromPath(NSURL(string: "app://localhost/welcome")!, url: NSURL(string: "app://localhost/welcome")!)!)
        XCTAssertEqual([:], bindParametersFromPath(NSURL(string: "app:///welcome")!, url: NSURL(string: "app://localhost/welcome")!)!)
        XCTAssertEqual([:], bindParametersFromPath(NSURL(string: "app://localhost/welcome")!, url: NSURL(string: "app:///welcome")!)!)
        XCTAssertEqual([:], bindParametersFromPath(NSURL(string: "app:///welcome")!, url: NSURL(string: "app:///welcome")!)!)
        
        XCTAssertNil(bindParametersFromPath(NSURL(string: "app://localhost/welcome")!, url: NSURL(string: "app://test.host/welcome")!))
    }
}