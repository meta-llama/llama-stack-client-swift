import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public protocol Agents {
  func create(request: Components.Schemas.CreateAgentRequest) async throws -> Components.Schemas.AgentCreateResponse
  
  func createSession(agent_id: String, request: Components.Schemas.CreateAgentSessionRequest) async throws -> Components.Schemas.AgentSessionCreateResponse
  
  func createTurn(agent_id: String, session_id: String, request: Components.Schemas.CreateAgentTurnRequest) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk>
}
