import Vapor

final class InvitationController: RouteCollection {
    func build(_ builder: RouteBuilder) throws {
        builder.versioned().auth() { build in
            build.post("/invitation", Project.parameter, "/accept", handler: accept)
            build.post("/invitation", Project.parameter, "/deny", handler: deny)
            build.post("/project", Project.parameter, "/invite", User.parameter, handler: invite)
        }
    }

    //MARK: - POST /invitation/{project}/{user_id}/accept
    func accept(_ req: Request) throws -> ResponseRepresentable {
        return try acceptDeny(req: req, type: .accept)
    }
    
    //MARK: - POST /invitation/{project}/{user_id}/deny
    func deny(_ req: Request) throws -> ResponseRepresentable {
        return try acceptDeny(req: req, type: .deny)
    }
    
    //MARK: - POST /project/{project_id}/invite/{user_id}
    func invite(_ req: Request) throws -> ResponseRepresentable {
        let authedUser = try req.user()
        let project: Project = try req.parameters.next()
        let invitedUser: User = try req.parameters.next()
        
        guard project.user_id == (try authedUser.assertExists()) else { throw Abort.badRequest }
        
        try ProjectUser(user_id: try invitedUser.assertExists(),
                        project_id: try project.assertExists(),
                        attending: false,
                        accepted: false).save()
        
        return Response(status: .created)
    }
    
    private func acceptDeny(req: Request, type: AcceptDenyType) throws -> ResponseRepresentable {
        let project: Project = try req.parameters.next()
        let projectUser: User = try req.user()
        
        guard let projectUserObject = try ProjectUser.makeQuery().filter(ProjectUser.Field.user_id, projectUser.id).filter(ProjectUser.Field.project_id, project.id).first() else { throw Abort.badRequest }
        
        if type == .deny {
            //the user wants to deny the request, so we're going to delete it
            try projectUserObject.delete()
            return Response(status: .ok)
        } else {
            projectUserObject.accepted = true
            try projectUserObject.save()
            
            return Response(status: .ok)
        }
    }
    
    enum AcceptDenyType {
        case accept
        case deny
    }
}

//MARK: - EmptyInitializable
extension InvitationController: EmptyInitializable { }
