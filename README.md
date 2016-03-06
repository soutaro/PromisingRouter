# PromisingRouter - Deferred openURL: Handling

Deep linking between apps in iOS is easy; `openURL:` to navigate from another app, and implement URL handling in your app.
The difficulty is that your app may not be able to handle URL.

What should be happen if user is not logged in yet?
Wait for login and resume URL processing?
Ignore the URL given?
Return to original app with error message?
(It depends on your app's requirements and common user expectation.)

How about if CoreData migration is pending?
Run the migration and continue processing URL?
What happen if your migration needs more than 3 minutes?
(It depends on your app's requirements and common user expectation, again.)

Your app may not be able to process open URL request right now, but will be able to decide how to do with them later.
This library is for such cases.

## Installation

Install the library via CocoaPods.

```
pod 'PromisingRouter'
```

## Getting Started

### 1. Instantiate Router

```swift
let router = PRRRouter(queue: dispatch_get_main_queue())
router.delegate = self
```

`queue` is GCD queue on which all actions and delegate methods are invoked.

### 2. Define Routings

```swift
let showPersonRouting = router.routingWithRoute("/people/:id")
let indexPeopleRouting = router.routingWithRoute("/people")
```

When your app finished startup process and ready to handle request:

```swift
showPersonRouting.action = ShowPersonAction()
indexPeopleRouting.action = IndexPersonAction()
```

`action` property of `PRRRouting` is **strong**. Make sure it does not make retain cycles.

### 3. Delegate openURL: handling to Router

In your app delegate:

```swift
func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
  router.dispatch(url, timeout: 10)
  return true
}
```

If associated routing has action when `dispatch` is called, it just run action.
If associated routing is defined but it does not have action yet, it wait until action is set, or finally timeout.
If there is no routing for given URL, it immediately fails and call delegate method.

### 4. Canceling Request

The library is expected to be used to handle `openURL:` app invocation.
It is good idea to cancel pending requests when user tries to leave your app.

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
  router.cancel()
}
```

## Defining Router

You can define your router and routings using out of the box `PRRRouter` class.

```swift
let router = PRRRouter(queue: dispatch_get_main_queue())
let openPageRouting = router.routingWithRoute("/pages/open")
```

However, the router and routings would be exposed as global variables, it should be a good pattern to define your custom router subclass.

```swift
class YourAppRouter : PRRRouter {
  let openPageRouting: PRRRouting
  let openSettingRouting: PRRRouting

  init() {
    super.init(queue: dispatch_get_main_queue())
    self.openPageRouting = self.routingWithRoute("/pages/open")
    self.openSettingRouting = self.routingWithRoute("/setting/:name")
  }
}
```

And assign the custom router instance to a global variable.
This would make maintaining global variable easy, and allows you to understand all routing definitions at glance.

## Defining Actions

Action object should conform to `PRRAction` protocol.
I believe this is usually a good pattern, because this library is to update actions during app life-cycle.

However, if you want a block based definition (which should be suitable for actions which would not be updated at all), use `PRRBlockAction`:

```swift
routing.action = PRRBlockAction { request in
  // Implement your action; make sure the block does not make retain cycle

  return nil
}
```

### Parameters

URL is available in actions through `PRRRequest` objects.

```swift
@objc public class PRRRequest : NSObject {
    public let url: NSURL
    public var parameters: [String : String] { get }
    public let pathParameters: [String : String]
    public let queryParameters: [String : String]
}
```

`parameters` property should be the most important one to you.
If parameters from path and query parameters conflicts, query parameters win in `parameters`.
Use `pathParameters` to access parameters from path.

Timeout and routing failures are notified to delegate with query parameters.

```swift
optional public func routerDidTimeout(router: PRRRouter, url: NSURL, parameters: [String : String])
optional public func routerDidFailToRoute(router: PRRRouter, url: NSURL, parameters: [String : String])
```

You can use the `parameters` dictionary or parse given `url` by yourself.

### Routing Result

Actions are a function which takes one `PRRRequest` object and returns an object which conforms to `PRRResult` protocol or nil.
You can just return nil if there is no information to pass to delegate.

```swift
func runActionForRoute(routing: PRRRouting, request: PRRRequest) -> PRRResult? {
  // Implement your action here

  return nil
}
```

You can also define a class to represent the result of an action, and return it in action.

```swift
class FailResult : PRRResult {
  let message: String

  init(message: String) {
    self.message = message
  }
}

func runActionForRoute(routing: PRRRouting, request: PRRRequest) -> PRRResult? {
  // Implement your action here

  return FailResult(message: "Not logged in yet")
}
```

Implement your delegate to do something against the result.

```swift
func routerDidRoute(router: PRRRouter, action: PRRAction, request: PRRRequest, result: PRRResult?) {
  if let result = result as? FailResult {
    print("Failed: message=\(result.message)")
  }
}
```

## Author

Soutaro Matsumoto (matsumoto@soutaro.com)
