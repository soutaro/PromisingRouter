import Foundation

func queryParametersWithURL(url: NSURL) -> [String: String] {
    guard let query = url.query else {
        return [:]
    }
    
    var dictionary: [String: String] = [:]
    
    let pairs: [(String, String?)] = query.componentsSeparatedByString("&").map { q in
        let pair = q.componentsSeparatedByString("=")
        return (pair[0], pair[1])
    }
    
    for pair in pairs {
        if let value = pair.1?.stringByRemovingPercentEncoding {
            dictionary[pair.0] = value
        }
    }
    
    return dictionary
}

func bindParametersFromPath(route: NSURL, url: NSURL) -> [String: String]? {
    guard route.scheme == url.scheme else {
        return nil
    }
    
    var binding: [String: String] = [:]
    
    if let routeHost = route.host, let urlHost = url.host {
        if routeHost != urlHost {
            // does not match
            return nil
        }
    }

    switch (route.pathComponents, url.pathComponents) {
    case (.Some(let routeComponents), .Some(let urlComponents)) where routeComponents.count == urlComponents.count:
        let pairs = routeComponents.zip(urlComponents)!
        for (routeComponent, pathComponent) in pairs {
            if routeComponent.hasPrefix(":") {
                // Bind
                let pattern = String(routeComponent.characters.dropFirst())
                binding[pattern] = pathComponent.stringByRemovingPercentEncoding
            } else if routeComponent == pathComponent {
                // ok
            } else {
                // Failure found
                return nil
            }
        }
        
        return binding
    case (.None, .None):
        return binding
    default:
        return nil
    }
}

extension Array {
    func zip<T>(a2: [T]) -> [(Element, T)]? {
        if self.count != a2.count {
            return nil
        }
        
        var result: [(Element, T)] = []
        
        self.enumerate().forEach {
            let a = $0.element
            let b = a2[$0.index]
            
            result.append((a, b))
        }
        
        return result
    }
}
