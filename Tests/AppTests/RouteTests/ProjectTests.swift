import XCTest
import Foundation
import Testing
import HTTP
@testable import Vapor
@testable import App

class ProjectTests: TestCase {
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
    
    func testGetAllProjects() throws {
        try createProject()
        
        let request = Request(method: .get,
                              uri: "/api/v1/projects",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: request)
            .assertStatus(is: .ok)
            .assertJSON("admin", passes: { json in json.array?.count == 1 })
            .assertJSON("accepted", passes: { json in json.array?.count == 0 })
            .assertJSON("pending", passes: { json in json.array?.count == 0 })
        
        let secondUser = try createUser(drop: drop, email: "email2@email.com")
        let secondUserId: Int = try! secondUser!.get("id")
        let acceptedProject = try createProject(adminId: Identifier(secondUserId))
        
        try ProjectUser(user_id: Identifier(userId), project_id: acceptedProject.id!, attending: true).save()
        
        let acceptedRequest = Request(method: .get,
                              uri: "/api/v1/projects",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: acceptedRequest)
            .assertStatus(is: .ok)
            .assertJSON("admin", passes: { json in json.array?.count == 1 })
            .assertJSON("accepted", passes: { json in json.array?.count == 1 })
            .assertJSON("pending", passes: { json in json.array?.count == 0 })
        
        let thirdUser = try createUser(drop: drop, email: "email3@email.com")
        let thirdUserId: Int = try! thirdUser!.get("id")
        let pendingProject = try createProject(adminId: Identifier(thirdUserId))
        
        try ProjectUser(user_id: Identifier(userId), project_id: pendingProject.id!, attending: false).save()
        
        let pendingRequest = Request(method: .get,
                                      uri: "/api/v1/projects",
                                      headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: pendingRequest)
            .assertStatus(is: .ok)
            .assertJSON("admin", passes: { json in json.array?.count == 1 })
            .assertJSON("accepted", passes: { json in json.array?.count == 1 })
            .assertJSON("pending", passes: { json in json.array?.count == 1 })
    }
    
    func testGetProject() throws {
        
    }
    
    func testUnauthorizedGetProject() throws {
        
    }
    
    func testCreateProject() throws {
        
    }
    
    @discardableResult
    private func createProject(adminId: Identifier? = nil) throws -> Project {
        let id = adminId ?? Identifier(userId)
        let newProject = Project(name: "Test project", user_id: id)
        try newProject.save()
        
        return newProject
    }
}

// MARK: Manifest
extension ProjectTests {
    static let allTests = [
        ("testGetAllProjects", testGetAllProjects),
        ("testGetProject", testGetProject),
        ("testUnauthorizedGetProject", testUnauthorizedGetProject),
        ("testCreateProject", testCreateProject)
    ]
}

