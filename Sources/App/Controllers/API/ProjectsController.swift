import Vapor

final class ProjectsController: RouteCollection {
    func build(_ builder: RouteBuilder) throws {
        builder.versioned().auth() { build in
            build.get("/projects", handler: projects)
            build.get("/project", Project.parameter, handler: project)
            build.post("/project", handler: createProject)
        }
    }
    
    //MARK: - GET /api/v1/projects
    func projects(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        
        var jsonResponse = JSON()
        try jsonResponse.set("admin", try user.adminProjects.all().makeJSON())
        try jsonResponse.set("accepted", try user.acceptedProjects().makeJSON())
        try jsonResponse.set("pending", try user.pendingProjects().makeJSON())
        
        return jsonResponse
    }
    
    //MARK: - GET /api/v1/project/{project_id}
    func project(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        let project: Project = try req.parameters.next()
        
        guard try user.userCanAccess(project: project) else { throw Abort.notFound }
        
        return try project.makeJSON()
    }
    
    //MARK: - POST /api/v1/project
    func createProject(_ req: Request) throws -> ResponseRepresentable {
        guard var submittedJSON = req.json else { throw Abort.badRequest }
        try submittedJSON.set(Project.Field.user_id, try req.user().id)
        
        let newProject = try Project(json: submittedJSON)
        try newProject.save()
        
        return try newProject.makeJSON()
    }
}

//MARK: - EmptyInitializable
extension ProjectsController: EmptyInitializable { }
