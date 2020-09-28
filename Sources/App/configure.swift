import Vapor

let languageServer = LanguageServer()

public func configure(_ app: Application) throws {
    languageServer.start()

    app.http.server.configuration.port = 3000
    app.http.server.configuration.supportPipelining = true
    app.http.server.configuration.requestDecompression = .enabled
    app.http.server.configuration.responseCompression = .enabled
    try routes(app)
}
