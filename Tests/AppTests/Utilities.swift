import Foundation
@testable import App
@testable import Vapor
import XCTest
import Testing
import FluentProvider

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
        Node.fuzzy = [Row.self, JSON.self, Node.self]
        Testing.onFail = XCTFail
    }
}
