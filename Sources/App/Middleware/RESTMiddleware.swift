import Vapor
import HTTP

class RESTMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let unauthorizedError = Abort(.unauthorized, reason: "Please include an API-KEY")
        
        guard let submittedAPIKey = request.headers[HeaderKey(APIKey.keyName)]?.string else { throw unauthorizedError }
        guard APIKey.apiKey == submittedAPIKey else {
            throw unauthorizedError
        }
        
        return try next.respond(to: request)
    }
}
