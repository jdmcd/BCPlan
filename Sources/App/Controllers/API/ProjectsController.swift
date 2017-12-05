import Vapor
import Fluent

final class ProjectsController: RouteCollection {
    func build(_ builder: RouteBuilder) throws {
        builder.versioned().auth() { build in
            build.get("/projects", handler: projects)
            build.get("/project", Project.parameter, handler: project)
            build.post("/project", handler: createProject)
            build.get("/project", Project.parameter, "/user", handler: searchUser)
        }
    }
    
    //MARK: - GET /api/v1/projects
    func projects(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        
        let adminProjects = try user.adminProjects.sort(Project.Field.id.rawValue, .descending).all()
        
        var jsonResponse = JSON()
        try jsonResponse.set("admin", adminProjects.makeJSON())
        try jsonResponse.set("accepted", try user.acceptedProjects().makeJSON())
        try jsonResponse.set("pending", try user.pendingProjects().makeJSON())
        
        return jsonResponse
    }
    
    //MARK: - GET /api/v1/project/{project_id}
    func project(_ req: Request) throws -> ResponseRepresentable {
        
        let user = try req.user()
        let project: Project = try req.parameters.next()
        
        guard try user.userCanAccess(project: project) else { throw Abort.notFound }
        
        let projectUsers = try project
            .projectUsers
            .makeQuery()
            .filter(ProjectUser.Field.project_id, try project.assertExists())
            .filter(ProjectUser.Field.user_id.rawValue, .notEquals, try user.assertExists())
            .all()
        
        var baseProjectJSON = try project.makeJSON()
        
        var memberJson = [JSON]()
        for projectUser in projectUsers {
            guard let user = try projectUser.user.get() else { continue }
            
            var json = try user.makeJSON()
            try json.set("accepted", projectUser.accepted)
            
            memberJson.append(json)
        }
        
        try baseProjectJSON.set("members", memberJson.makeJSON())
        
        var meetingDateJson = [JSON]()
        let meetingDates = try project.meetingDates.sort(MeetingDate.Field.date.rawValue, .ascending).all()
        var votedFor: Int?
        
        for meetingDate in meetingDates {
            var json = try meetingDate.makeJSON()
            
            let votes = try meetingDate.userVotes.all()
            
            try json.set("votes", votes.count)
            try json.set("selected", project.meeting_date_id == meetingDate.id)
            
            if (votes.flatMap { $0.id?.int }).contains(user.id!.int!) {
                votedFor = meetingDate.id!.int
            }
            
            meetingDateJson.append(json)
        }
        
        try baseProjectJSON.set("dates", meetingDateJson.makeJSON())
        
        let projectUser = try user.projectUsers.filter(ProjectUser.Field.project_id, project.assertExists()).first()
        
        var attendingUsers = try projectUsers.filter { $0.attending }.flatMap { try $0.user.get() }
        if let pU = projectUser, pU.attending {
            attendingUsers.append(user)
            try baseProjectJSON.set("attending", true)
        } else {
            try baseProjectJSON.set("attending", false)
        }
        
        try baseProjectJSON.set("attendingUsers", attendingUsers.makeJSON())
        try baseProjectJSON.set("votedFor", votedFor)
        
        return baseProjectJSON
    }
    
    //MARK: - POST /api/v1/project
    func createProject(_ req: Request) throws -> ResponseRepresentable {
        guard var submittedJSON = req.json else { throw Abort.badRequest }
        
        //custom set fields
        try submittedJSON.set(Project.Field.user_id, try req.user().id)
        try submittedJSON.set(Project.Field.meeting_date_id, nil)
        
        let newProject = try Project(json: submittedJSON)
        try newProject.save()

        //save the project user for the admin
        try ProjectUser(
            user_id: try req.user().assertExists(),
            project_id: try newProject.assertExists(),
            attending: false,
            accepted: true
            ).save()
        
        return try newProject.makeJSON()
    }
    
    //MARK: - GET /api/v1/project/{project_id}/user?query={query}
    func searchUser(_ req: Request) throws -> ResponseRepresentable {
        let project: Project = try req.parameters.next()
        let user = try req.user()
        
        guard project.user_id == (try user.assertExists()) else { throw Abort.notFound }
        guard let query = req.query?["query"]?.string else { throw Abort.badRequest }
        
        let currentMemberIds = try project.users.all().flatMap { $0.id }
        
        let userQuery = try User
            .makeQuery()
            .filter(User.Field.id.rawValue, .notEquals, user.id)
            .filter(User.Field.id.rawValue, notIn: currentMemberIds)
            .or { orQuery in
                try orQuery.filter("name", .contains, query.lowercased())
                try orQuery.filter("email", .contains, query.lowercased())
        }
        
        return try userQuery.all().makeJSON()
    }
}

//MARK: - EmptyInitializable
extension ProjectsController: EmptyInitializable { }
