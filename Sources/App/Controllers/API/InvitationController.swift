import Vapor

final class InvitationController: RouteCollection {
    func build(_ builder: RouteBuilder) throws {
        builder.versioned().auth() { build in
            build.post("/invitation", ProjectUser.parameter, "/accept", handler: accept)
            build.post("/invitation", ProjectUser.parameter, "/deny", handler: deny)
        }
    }

    //MARK: - POST /invitation/{project_user_id}/accept
    func accept(_ req: Request) throws -> ResponseRepresentable {
        return try acceptDeny(req: req, type: .accept)
    }
    
    //MARK: - POST /invitation/{project_user_id}/deny
    func deny(_ req: Request) throws -> ResponseRepresentable {
        return try acceptDeny(req: req, type: .deny)
    }
    
    private func acceptDeny(req: Request, type: AcceptDenyType) throws -> ResponseRepresentable {
        let projectUser: ProjectUser = try req.parameters.next()
        let user = try req.user()
        guard let userId = user.id else { throw Abort.badRequest }
        guard projectUser.user_id == userId else { throw Abort.notFound }
        
        if type == .deny {
            try projectUser.delete()
            return Response(status: .ok)
        } else {
            projectUser.accepted = true
            try projectUser.save()
            
            return try projectUser.makeJSON()
        }
    }
    
    enum AcceptDenyType {
        case accept
        case deny
    }
}

//MARK: - EmptyInitializable
extension InvitationController: EmptyInitializable { }
