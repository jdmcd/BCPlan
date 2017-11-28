import Foundation
@testable import App
@testable import Vapor
import XCTest
import Testing
import FluentProvider
import HTTP

extension Droplet {
    static func testable() throws -> Droplet {
        var config = try Config(arguments: ["vapor", "--env=test"])
        try config.set("app.API-KEY", FakeAPIKey.apiKey)
        try config.setup()
        
        let drop = try Droplet(config)
        try drop.setup()
        
        return drop
    }
    
    func serveInBackground() throws {
        background {
            try! self.run()
        }
        console.wait(seconds: 0.5)
    }
}

struct FakeAPIKey {
    static let apiKey = "test-key"
}

class TestCase: XCTestCase {
    override func setUp() {
        try! User.makeQuery().delete()
        try! Project.makeQuery().delete()
        try! MeetingDate.makeQuery().delete()
        try! ProjectUser.makeQuery().delete()
        try! Token.makeQuery().delete()
        try! Pivot<User, MeetingDate>.makeQuery().delete()
        
        Node.fuzzy = [Row.self, JSON.self, Node.self]
        Testing.onFail = XCTFail
    }
    
    //MARK: - createUser
    @discardableResult
    func createUser(drop: Droplet, email: String = "email@email.com") throws -> JSON? {
        var json = JSON()
        
        try json.set(User.Field.name, "name")
        try json.set(User.Field.email, email)
        try json.set(User.Field.password, "password")
        
        let body = try Body(json)
        
        let request = Request(method: .post,
                              uri: "/api/v1/register",
                              headers: ["Content-Type": "application/json", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey],
                              body: body)
        
        let response = try drop.testResponse(to: request)
        guard let responseJson = response.json else { XCTFail(); return nil }
        return responseJson
    }
}
