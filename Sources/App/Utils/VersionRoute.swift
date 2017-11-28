import Routing
import AuthProvider

struct VersionRoute {
    static let path = "api/v1"
}

extension RouteBuilder {
    func version(handler: (RouteBuilder) -> ()) {
        group(path: [VersionRoute.path], handler: handler)
    }
    
    func versioned() -> RouteBuilder {
        return grouped(VersionRoute.path)
    }
}

extension RouteBuilder {
    fileprivate func middleware() -> [Middleware] {
        return [TokenAuthenticationMiddleware(User.self)]
    }
    
    func auth(handler: (RouteBuilder) -> ()) {
        group(middleware: middleware(), handler: handler)
    }
    
    func authed() -> RouteBuilder {
        return grouped(middleware())
    }
}
