import Vapor
import LanguageServerProtocol

func routes(_ app: Application) throws {
    app.post("request", "initialize") { req -> EventLoopFuture<InitializeRequest.Response> in
        let parameter = try req.content.decode(InitializeRequestParameter.self)
        let workspacePath = parameter.workspacePath
        let documentPath = parameter.documentPath
        let text = parameter.text

        let promise = req.eventLoop.makePromise(of: InitializeRequest.Response.self)
        languageServer.sendInitializeRequest(workspacePath: workspacePath) {
            switch $0 {
            case .success(let response):
                languageServer.sendDidOpenNotification(documentPath: documentPath, text: text)
                promise.succeed(response)
            case .failure(let error):
                promise.fail(error)
            }
        }

        return promise.futureResult
    }

    app.post("request", "textDocument", "completion") { req -> EventLoopFuture<[CompletionItem]> in
        let parameter = try req.content.decode(CompletionRequestParameter.self)
        let documentPath = parameter.documentPath
        let line = parameter.line
        let character = parameter.character
        let prefix = parameter.prefix

        let promise = req.eventLoop.makePromise(of: [CompletionItem].self)
        languageServer.sendCompletionRequest(documentPath: documentPath, line: line, character: character) {
            switch $0 {
            case .success(let response):
                let items = response.items
                    .filter {
                        if let prefix = prefix, !prefix.isEmpty {
                            return $0.label.contains(prefix)
                        } else {
                            return true
                        }
                    }
                    .sorted {
                        if let prefix = prefix, !prefix.isEmpty {
                            if $0.label.starts(with: prefix) && $1.label.starts(with: prefix) {
                                return $0.label < $1.label
                            }
                            if $0.label.starts(with: prefix) {
                                return true
                            }
                            if $1.label.starts(with: prefix) {
                                return false
                            }
                            return $0.label < $1.label
                        } else {
                            return $0.label < $1.label
                        }
                    }
                promise.succeed(items)
            case .failure(let error):
                promise.fail(error)
            }
        }

        return promise.futureResult
    }

    app.post("notification", "initialized") { req -> [String] in
        languageServer.sendInitializedNotification()
        return []
    }

    app.post("notification", "textDocument", "didOpen") { req -> [String] in
        let parameter = try req.content.decode(DidOpenRequestParameter.self)
        let documentPath = parameter.documentPath
        let text = parameter.text
        languageServer.sendDidOpenNotification(documentPath: documentPath, text: text)
        return []
    }

    app.post("notification", "textDocument", "didChange") { req -> [String] in
        let parameter = try req.content.decode(DidChangeRequestParameter.self)
        let documentPath = parameter.documentPath
        let text = parameter.text
        let version = parameter.version
        languageServer.sendDidChangeNotification(documentPath: documentPath, text: text, version: version)
        return []
    }
}

struct InitializeRequestParameter: Decodable {
    let workspacePath: String
    let documentPath: String
    let text: String
}

struct CompletionRequestParameter: Decodable {
    let documentPath: String
    let line: Int
    let character: Int
    let prefix: String?
}

struct DidOpenRequestParameter: Decodable {
    let documentPath: String
    let text: String
}

struct DidChangeRequestParameter: Decodable {
    let documentPath: String
    let text: String
    let version: Int
}

extension InitializeRequest.Response: Content {}
extension CompletionRequest.Response: Content {}
extension CompletionItem: Content {}
