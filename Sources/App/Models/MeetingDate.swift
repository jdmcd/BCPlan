import Vapor
import FluentProvider

final class MeetingDate: Model {
    var storage = Storage()
    
    var date: Date
    var project_id: Identifier
    
    var project: Parent<MeetingDate, Project> {
        return parent(id: project_id)
    }

    init(date: Date, project_id: Identifier) {
        self.date = date
        self.project_id = project_id
    }
    
    init(row: Row) throws {
        date = try row.get(MeetingDate.Field.date)
        project_id = try row.get(MeetingDate.Field.project_id)
    }

    init(json: JSON) throws {
        date = try json.get(MeetingDate.Field.date)
        project_id = try json.get(MeetingDate.Field.project_id)
    }
    
    func makeRow() throws -> Row {
        var row = Row()

        try row.set(MeetingDate.Field.date, date)
        try row.set(MeetingDate.Field.project_id, project_id)

        return row
    }
}

//MARK: - Preparation
extension MeetingDate: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { builder in
            builder.id()
            builder.date(Field.date.rawValue)
            builder.parent(Project.self)
        })
    }
    
    static func revert(_ database: Database) throws {   
    }
}

//MARK: - JSONConvertible
extension MeetingDate: JSONConvertible {
    func makeJSON() throws -> JSON {
        var json = JSON()

        try json.set(MeetingDate.Field.id, id)
        try json.set(MeetingDate.Field.date, date)
        try json.set(MeetingDate.Field.project_id, project_id)
        try json.set(MeetingDate.createdAtKey, createdAt)
        try json.set(MeetingDate.updatedAtKey, updatedAt)

        return json
    }
}


//MARK: - Timestampable
extension MeetingDate: Timestampable { }

//MARK: - Field
extension MeetingDate {
    enum Field: String {
        case id
        case date
        case project_id
    }
}
