import XCTest
import Foundation
import Testing
import HTTP
@testable import Vapor
@testable import App

class MeTests: TestCase {
    let drop = try! Droplet.testable()
    var userJson: JSON!
    
    override func setUp() {
        super.setUp()
        
        try! Token.makeQuery().delete()
        try! User.makeQuery().delete()
        
        userJson = try! createUser()
    }
    
    func testAuthorized() throws {
        guard let token = userJson["token"]?.string else { XCTFail(); return }
        
        let request = Request(method: .get,
                              uri: "/api/v1/me",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: request)
            .assertStatus(is: .ok)
            .assertJSON("id", passes: { json in json.int != nil })
            .assertJSON("token", passes: { json in json.string != nil })
            .assertJSON("name", equals: userJson["name"]?.string)
            .assertJSON("email", equals: userJson["email"]?.string)
            .assertJSON("password", passes: { json in json.string == nil })
    }
    
    func testNotAuthorized() throws {
        let request = Request(method: .get,
                              uri: "/api/v1/me",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer RANDOMTOKEN", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: request)
            .assertStatus(is: .unauthorized)
    }
    
    func testResetPasswordSuccess() throws {
        guard let token = userJson["token"]?.string else { XCTFail(); return }
        
        var resetPasswordJson = JSON()
        try resetPasswordJson.set("oldPassword", "password")
        try resetPasswordJson.set("newPassword", "newpassword")
        
        let body = try Body(resetPasswordJson)
        
        let request = Request(method: .patch,
                              uri: "/api/v1/password",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey],
                              body: body)
        
        try drop.testResponse(to: request)
            .assertStatus(is: .ok)
            .assertJSON("id", passes: { json in json.int != nil })
            .assertJSON("token", passes: { json in json.string != nil })
        
        //Lets try and login with the old password and make sure it fails
        var loginJson = JSON()
        try loginJson.set(User.Field.email, "email@email.com")
        try loginJson.set(User.Field.password, "password")
        
        let loginBody = try Body(loginJson)
        
        let loginRequest = Request(method: .post,
                              uri: "/api/v1/login",
                              headers: ["Content-Type": "application/json", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey],
                              body: loginBody)
        
        try drop.testResponse(to: loginRequest)
            .assertStatus(is: .badRequest)
            .assertJSON("id", passes: { json in json.int == nil })
            .assertJSON("token", passes: { json in json.string == nil })
    }
    
    func testResetPasswordWrongOldPassword() throws {
        guard let token = userJson["token"]?.string else { XCTFail(); return }
        
        var resetPasswordJson = JSON()
        try resetPasswordJson.set("oldPassword", "wrong password")
        try resetPasswordJson.set("newPassword", "newpassword")
        
        let body = try Body(resetPasswordJson)
        
        let request = Request(method: .patch,
                              uri: "/api/v1/password",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey],
                              body: body)
        
        try drop.testResponse(to: request)
            .assertStatus(is: .unauthorized)
            .assertJSON("id", passes: { json in json.int == nil })
            .assertJSON("token", passes: { json in json.string == nil })
    }
    
    //MARK: - createUser
    @discardableResult
    private func createUser() throws -> JSON? {
        var json = JSON()
        
        try json.set(User.Field.name, "name")
        try json.set(User.Field.email, "email@email.com")
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

// MARK: Manifest
extension MeTests {
    static let allTests = [
        ("testAuthorized", testAuthorized),
        ("testNotAuthorized", testNotAuthorized),
        ("testResetPasswordSuccess", testResetPasswordSuccess),
        ("testResetPasswordWrongOldPassword", testResetPasswordWrongOldPassword)
    ]
}
