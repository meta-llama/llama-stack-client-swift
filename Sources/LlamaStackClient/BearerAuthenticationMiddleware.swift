import OpenAPIRuntime
import Foundation
import HTTPTypes

package struct BearerAuthenticationMiddleware {
    private let token: String
    
    package init(token: String) {
        self.token = token
    }
    
    private var bearerToken: String {
        "Bearer \(token)"
    }
}

extension BearerAuthenticationMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = bearerToken
        return try await next(request, body, baseURL)
    }
}
