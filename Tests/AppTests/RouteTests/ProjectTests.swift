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
            .assertJSON("chosenDate", passes: { json in json.string == nil })
        
        let secondUser = try createUser(drop: drop, email: "email2@email.com")
        let secondUserId: Int = try! secondUser!.get("id")
        let acceptedProject = try createProject(adminId: Identifier(secondUserId))
        
        try ProjectUser(user_id: Identifier(userId), project_id: acceptedProject.id!, attending: false, accepted: true).save()
        
        let acceptedRequest = Request(method: .get,
                              uri: "/api/v1/projects",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: acceptedRequest)
            .assertStatus(is: .ok)
            .assertJSON("admin", passes: { json in json.array?.count == 1 })
            .assertJSON("accepted", passes: { json in json.array?.count == 1 })
            .assertJSON("pending", passes: { json in json.array?.count == 0 })
            .assertJSON("chosenDate", passes: { json in json.string == nil })
        
        let thirdUser = try createUser(drop: drop, email: "email3@email.com")
        let thirdUserId: Int = try! thirdUser!.get("id")
        let pendingProject = try createProject(adminId: Identifier(thirdUserId))
        
        try ProjectUser(user_id: Identifier(userId), project_id: pendingProject.id!, attending: false, accepted: false).save()
        
        let pendingRequest = Request(method: .get,
                                      uri: "/api/v1/projects",
                                      headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: pendingRequest)
            .assertStatus(is: .ok)
            .assertJSON("admin", passes: { json in json.array?.count == 1 })
            .assertJSON("accepted", passes: { json in json.array?.count == 1 })
            .assertJSON("pending", passes: { json in json.array?.count == 1 })
            .assertJSON("chosenDate", passes: { json in json.string == nil })
    }
    
    func testGetProject() throws {
        let project = try createProject()
        
        let request = Request(method: .get,
                              uri: "/api/v1/project/\(project.id!.int!)",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: request)
            .assertStatus(is: .ok)
            .assertJSON("id", passes: { $0.int == project.id!.int! })
            .assertJSON("name", passes: { $0.string == project.name })
            .assertJSON("user_id", passes: { $0.int == project.user_id.int! })
            .assertJSON("chosenDate", passes: { json in json.string == nil })
    }
    
    func testUnauthorizedGetProject() throws {
        let secondUser = try createUser(drop: drop, email: "email2@email.com")
        let secondUserId: Int = try! secondUser!.get("id")
        let project = try createProject(adminId: Identifier(secondUserId))
        
        let request = Request(method: .get,
                              uri: "/api/v1/project/\(project.id!.int!)",
            headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey])
        
        try drop.testResponse(to: request).assertStatus(is: .notFound)
    }
    
    func testCreateProject() throws {
        var body = JSON()
        try body.set("name", "Project name")
        try body.set("user_id", 0)
        try body.set("chosenDate", "01/01/01 00:00:00")
        
        let request = Request(method: .post,
                              uri: "/api/v1/project",
                              headers: ["Content-Type": "application/json", "Authorization": "Bearer \(token)", HeaderKey(APIKey.keyName): FakeAPIKey.apiKey],
                              body: try Body(body))
        
        try drop.testResponse(to: request)
            .assertStatus(is: .ok)
            .assertJSON("id", passes: { $0.int != nil })
            .assertJSON("name", passes: { $0.string != nil })
            .assertJSON("user_id", equals: userId)
            .assertJSON("chosenDate", passes: { json in json.string == nil })
        
        XCTAssertEqual(try ProjectUser.makeQuery().count(), 1)
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

