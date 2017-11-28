import Vapor
import FluentProvider

final class Project: Model {
    var storage = Storage()
    
    var name: String
    
    //the admin of the project
    var user_id: Identifier

    var user: Parent<Project, User> {
        return parent(id: user_id)
    }

    init(name: String, user_id: Identifier) {
        self.name = name
        self.user_id = user_id
    }
    
    init(row: Row) throws {
        name = try row.get(Project.Field.name)
        user_id = try row.get(Project.Field.user_id)
    }

    init(json: JSON) throws {
        name = try json.get(Project.Field.name)
        user_id = try json.get(Project.Field.user_id)
    }
    
    func makeRow() throws -> Row {
        var row = Row()

        try row.set(Project.Field.name, name)
        try row.set(Project.Field.user_id, user_id)

        return row
    }
}

//MARK: - Preparation
extension Project: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { builder in
            builder.id()
            builder.string(Project.Field.name)
            builder.parent(User.self)
        })
    }
    
    static func revert(_ database: Database) throws {   
    }
}

//MARK: - JSONConvertible
extension Project: JSONConvertible {
    func makeJSON() throws -> JSON {
        var json = JSON()

        try json.set(Project.Field.id, id)
        try json.set(Project.Field.name, name)
        try json.set(Project.Field.user_id, user_id)
        try json.set(Project.createdAtKey, createdAt)
        try json.set(Project.updatedAtKey, updatedAt)

        return json
    }
}


//MARK: - Timestampable
extension Project: Timestampable { }

//MARK: - Field
extension Project {
    enum Field: String {
        case id
        case name
        case user_id
    }
}
