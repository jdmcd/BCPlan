import FluentProvider
import MySQLProvider
import Vapor
import Sessions
import AuthProvider
import Cookies

extension Config {
    public func setup() throws {
        Node.fuzzy = [Row.self, JSON.self, Node.self]
        
        try setupProviders()
        setupPreparations()
        try setupApiKey()
    }
    
    /// Configure providers
    private func setupProviders() throws {
        try addProvider(FluentProvider.Provider.self)
        try addProvider(MySQLProvider.Provider.self)
        try addProvider(AuthProvider.Provider.self)
    }
    
    private func setupApiKey() throws {
        do {
            APIKey.apiKey = try get("app.API-KEY")
        } catch {
            throw Abort(.internalServerError, reason: "Please add an API-KEY")
        }
    }
}
