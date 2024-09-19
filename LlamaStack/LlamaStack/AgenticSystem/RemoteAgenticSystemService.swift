import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public class RemoteAgentsService: AgentsService {
  
  private let url: URL
  private let client: Client
  private let encoder = JSONEncoder()
  
  public init (url: URL) {
    self.url = url
    self.client = Client(serverURL: url, transport: URLSessionTransport())
  }
  
  public func create(request: Components.Schemas.CreateAgentRequest) async throws -> Components.Schemas.AgentCreateResponse {
    let response = try await client.post_sol_agents_sol_create(body: Operations.post_sol_agents_sol_create.Input.Body.json(request))
    return try response.ok.body.json
  }
  
  public func createSession(request: Components.Schemas.CreateAgentSessionRequest) async throws -> Components.Schemas.AgentSessionCreateResponse {
    let response = try await client.post_sol_agents_sol_session_sol_create(body: Operations.post_sol_agents_sol_session_sol_create.Input.Body.json(request))
    return try response.ok.body.json
  }
  
  public func createTurn(request: Components.Schemas.CreateAgentTurnRequest) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    return AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> { continuation in
      Task {
        do {
          let response = try await self.client.post_sol_agents_sol_turn_sol_create(
            body: Operations.post_sol_agents_sol_turn_sol_create.Input.Body.json(request)
          )
          let stream = try response.ok.body.text_event_hyphen_stream.asDecodedServerSentEventsWithJSONData(
            of: Components.Schemas.AgentTurnResponseStreamChunk.self
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
