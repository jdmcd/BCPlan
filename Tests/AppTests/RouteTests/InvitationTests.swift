import XCTest
import Foundation
import Testing
import HTTP
@testable import Vapor
@testable import App

class InvitationTests: TestCase {
    let drop = try! Droplet.testable()
    var userJson: JSON!
    var token = ""
    var userId: Int = 0
    
    override func setUp() {
        super.setUp()
        
        userJson = try! createUser(drop: drop)
        userId = try! userJson.get("id")
        token = userJson["token"]?.string ?? ""
    }
    
    func testAcceptInvitation() throws {
        let project = Project(name: "", user_id: Identifier(userId))
        try project.save()
        
        let secondUser = try createUser(drop: drop, email: "email2@email.com")
        let secondUserId: Int = try secondUser!.get("id")
        
        let projectUser = ProjectUser(user_id: Identifier(secondUserId), project_id: project.id!, attending: false, accepted: false)
        try projectUser.save()
        
        let badRequest = Request(method: .post,
                              uri: "/api/v1/invitation/\(projectUser.id!.int!)/accept",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: badRequest)
            .assertStatus(is: .notFound)

        let secondUserToken = secondUser!["token"]?.string ?? ""
        projectUser.user_id = Identifier(secondUserId)
        try projectUser.save()
        
        let successRequest = Request(method: .post,
                                 uri: "/api/v1/invitation/\(try projectUser.assertExists().int!)/accept",
            headers: ["Content-Type": "application/json", "Authorization": "Bearer \(secondUserToken)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])

        try drop.testResponse(to: successRequest)
            .assertStatus(is: .ok)
            .assertJSON("id", passes: { $0.int != nil })
            .assertJSON("user_id", passes: { $0.int != nil })
            .assertJSON("project_id", passes: { $0.int != nil })
            .assertJSON("attending", passes: { $0.bool == false })
            .assertJSON("accepted", passes: { $0.bool == true })
    }
    
    func testDenyInvitation() throws {
        let project = Project(name: "", user_id: Identifier(userId))
        try project.save()
        
        let secondUser = try createUser(drop: drop, email: "email2@email.com")
        let secondUserId: Int = try secondUser!.get("id")
        
        let projectUser = ProjectUser(user_id: Identifier(secondUserId), project_id: project.id!, attending: false, accepted: false)
        try projectUser.save()
        
        let secondUserToken = secondUser!["token"]?.string ?? ""
        projectUser.user_id = Identifier(secondUserId)
        try projectUser.save()
        
        let successRequest = Request(method: .post,
                                     uri: "/api/v1/invitation/\(try projectUser.assertExists().int!)/deny",
            headers: ["Content-Type": "application/json", "Authorization": "Bearer \(secondUserToken)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: successRequest)
            .assertStatus(is: .ok)

        XCTAssertNil(try ProjectUser.find(projectUser.id))
    }
}

// MARK: Manifest
extension InvitationTests {
    static let allTests = [
        ("testAcceptInvitation", testAcceptInvitation),
        ("testDenyInvitation", testDenyInvitation)
    ]
}

