import Foundation

@objc public class PRRRequest: NSObject {
    /**
     URL the app is invoked with.
     */
    public let url: NSURL
    
    /**
     Dictionary for parameters from path.
     */
    public let pathParameters: [String: String]
    
    /**
     Dictionary for parameters from query string.
     */
    public let queryParameters: [String: String]
    
    init(url: NSURL, pathParameters: [String: String], queryParameters: [String: String]) {
        self.url = url
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
    }
    
    /**
     All parameters with from path and from query string.
     Parameters from query string is contained in this dictionary if duplicated.
     */
    public var parameters: [String: String] {
        get {
            var parameters: [String: String] = [:]
            
            for (key, value) in self.pathParameters {
                parameters[key] = value
            }
            
            for (key, value) in self.queryParameters {
                parameters[key] = value
            }
            
            return parameters
        }
    }
}