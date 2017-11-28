import Vapor

final class MeetingDateController: RouteCollection {
    func build(_ builder: RouteBuilder) throws {
        builder.version() { build in
            build.post("/project", Project.parameter, "/dates", handler: addDatesToProject)
        }
    }

    //MARK: - POST /project/{project_id}/dates
    func addDatesToProject(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        let project: Project = try req.parameters.next()
        
        guard try user.assertExists() == project.user_id else { throw Abort.notFound }
        guard let jsonArray = req.json?.array else { throw Abort.badRequest }
    
        for var jsonObject in jsonArray {
            try jsonObject.set("project_id", try project.assertExists())
            
            try MeetingDate(json: jsonObject).save()
        }
        
        return Response(status: .ok)
    }
    
}

//MARK: - EmptyInitializable
extension MeetingDateController: EmptyInitializable { }
