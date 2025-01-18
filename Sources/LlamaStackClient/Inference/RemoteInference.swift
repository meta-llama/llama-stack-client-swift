import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public class RemoteInference: Inference {
  private let url: URL
  private let client: Client
  private let encoder = JSONEncoder()
  
  public init (url: URL) {
    self.url = url
    self.client = Client(serverURL: url, transport: URLSessionTransport())
  }
  
  public func chatCompletion(request: Components.Schemas.ChatCompletionRequest) async throws -> AsyncStream<Components.Schemas.ChatCompletionResponseStreamChunk> {
    assert(request.stream == true, "Only supports streaming right now")
    
    return AsyncStream<Components.Schemas.ChatCompletionResponseStreamChunk> { continuation in
      Task {
        do {
          let response = try await self.client.post_sol_v1_sol_inference_sol_chat_hyphen_completion(
            body: Operations.post_sol_v1_sol_inference_sol_chat_hyphen_completion.Input.Body.json(request)
          )
          let stream = try response.ok.body.text_event_hyphen_stream.asDecodedServerSentEventsWithJSONData(
            of: Components.Schemas.ChatCompletionResponseStreamChunk.self
          )
          for try await event in stream {
            continuation.yield(event.data!)
          }
          continuation.finish()
        } catch {
          print(error)
        }
      }
    }
  }
}
