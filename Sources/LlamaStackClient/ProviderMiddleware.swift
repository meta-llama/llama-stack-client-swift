import OpenAPIRuntime
import Foundation
import HTTPTypes

package struct ProviderMiddleware {
    private let token: String
    
    package init(token: String) {
        self.token = token
    }
    
    private var providerToken: String {
      let key_dict = ["together_api_key": token]
      if let jsonData = try? JSONSerialization.data(withJSONObject: key_dict, options: []),
         let jsonString = String(data: jsonData, encoding: .utf8) {
        return jsonString
      }
      return ""
  }
}

extension ProviderMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[HTTPField.Name("X-LlamaStack-Provider-Data")!] = providerToken
        return try await next(request, body, baseURL)
    }
}
