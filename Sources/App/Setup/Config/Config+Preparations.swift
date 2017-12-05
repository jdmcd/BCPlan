import Vapor
import Fluent

extension Config {
    func setupPreparations() {
        preparations.append(User.self)
        preparations.append(Token.self)
        preparations.append(Project.self)
        preparations.append(ProjectUser.self)
        preparations.append(MeetingDate.self)
        preparations.append(Pivot<User, MeetingDate>.self)
        preparations.append(AddAcceptedToProjectUser.self)
        preparations.append(AddChosenDateToProject.self)
        preparations.append(AddMeetingDateIdToProject.self)
    }
}
