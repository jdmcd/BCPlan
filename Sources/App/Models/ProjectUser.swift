import Vapor
import FluentProvider

//represents an invited user
final class ProjectUser: Model {
    var storage = Storage()
    
    var user_id: Identifier
    var project_id: Identifier
    
    //used to indicate whether the user will attend once a final meeting time has been determined
    var attending: Bool
    
    //used to indicate if the user accepts the invitation to join the group
    var accepted: Bool

    var user: Parent<ProjectUser, User> {
        return parent(id: user_id)
    }
    
    var project: Parent<ProjectUser, Project> {
        return parent(id: project_id)
    }

    init(user_id: Identifier, project_id: Identifier, attending: Bool, accepted: Bool) {
        self.user_id = user_id
        self.project_id = project_id
        self.attending = attending
        self.accepted = accepted
    }
    
    init(row: Row) throws {
        user_id = try row.get(ProjectUser.Field.user_id)
        project_id = try row.get(ProjectUser.Field.project_id)
        attending = try row.get(ProjectUser.Field.attending)
        accepted = try row.get(ProjectUser.Field.accepted)
    }

    init(json: JSON) throws {
        user_id = try json.get(ProjectUser.Field.user_id)
        project_id = try json.get(ProjectUser.Field.project_id)
        attending = try json.get(ProjectUser.Field.attending)
        accepted = try json.get(ProjectUser.Field.accepted)
    }
    
    func makeRow() throws -> Row {
        var row = Row()

        try row.set(ProjectUser.Field.user_id, user_id)
        try row.set(ProjectUser.Field.project_id, project_id)
        try row.set(ProjectUser.Field.attending, attending)
        try row.set(ProjectUser.Field.accepted, accepted)

        return row
    }
    
    func willUpdate() {
        if attending {
            accepted = true
        }
    }
    
    func willCreate() {
        if attending {
            accepted = true
        }
    }
}

//MARK: - Preparation
extension ProjectUser: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { builder in
            builder.id()
            builder.parent(User.self)
            builder.parent(Project.self)
            builder.bool(ProjectUser.Field.attending)
        })
    }
    
    static func revert(_ database: Database) throws {   
    }
}

struct AddAcceptedToProjectUser: Preparation {
    static func prepare(_ database: Database) throws {
        try database.modify(ProjectUser.self) { modifier in
            modifier.bool(ProjectUser.Field.accepted.rawValue)
        }
    }
    
    static func revert(_ database: Database) throws {
        
    }
}

//MARK: - JSONConvertible
extension ProjectUser: JSONConvertible {
    func makeJSON() throws -> JSON {
        var json = JSON()

        try json.set(ProjectUser.Field.id, id)
        try json.set(ProjectUser.Field.user_id, user_id)
        try json.set(ProjectUser.Field.project_id, project_id)
        try json.set(ProjectUser.Field.attending, attending)
        try json.set(ProjectUser.Field.accepted, accepted)
        try json.set(ProjectUser.createdAtKey, createdAt)
        try json.set(ProjectUser.updatedAtKey, updatedAt)

        return json
    }
}


//MARK: - Timestampable
extension ProjectUser: Timestampable { }

//MARK: - Field
extension ProjectUser {
    enum Field: String {
        case id
        case user_id
        case project_id
        case attending
        case accepted
    }
}
