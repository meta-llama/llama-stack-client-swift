import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public class RemoteAgenticSystemService: AgenticSystemService {
  
  private let url: URL
  private let client: Client
  private let encoder = JSONEncoder()
  
  public init (url: URL) {
    self.url = url
    self.client = Client(serverURL: url, transport: URLSessionTransport())
  }
  
  public func create(request: Components.Schemas.CreateAgenticSystemRequest) async throws -> Components.Schemas.AgenticSystemCreateResponse {
    let response = try await client.post_sol_agentic_system_sol_create(body: Operations.post_sol_agentic_system_sol_create.Input.Body.json(request))
    return try response.ok.body.json
  }
  
  public func createSession(request: Components.Schemas.CreateAgenticSystemSessionRequest) async throws -> Components.Schemas.AgenticSystemSessionCreateResponse {
    let response = try await client.post_sol_agentic_system_sol_session_sol_create(body: Operations.post_sol_agentic_system_sol_session_sol_create.Input.Body.json(request))
    return try response.ok.body.json
  }
  
  public func createTurn(request: Components.Schemas.CreateAgenticSystemTurnRequest) async throws -> AsyncStream<Components.Schemas.AgenticSystemTurnResponseStreamChunk> {
    return AsyncStream<Components.Schemas.AgenticSystemTurnResponseStreamChunk> { continuation in
      Task {
        do {
          let response = try await self.client.post_sol_agentic_system_sol_turn_sol_create(
            body: Operations.post_sol_agentic_system_sol_turn_sol_create.Input.Body.json(request)
          )
          let stream = try response.ok.body.text_event_hyphen_stream.asDecodedServerSentEventsWithJSONData(
            of: Components.Schemas.AgenticSystemTurnResponseStreamChunk.self
          )
          do {
            for try await event in stream {
              continuation.yield(event.data!)
            }
          } catch {
            print("Agentic stream failed: " + error.localizedDescription)
          }
          continuation.finish()
        } catch {
          print(error)
        }
      }
    }
  }
}
