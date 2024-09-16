import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public protocol AgenticSystemService {
  func create(request: Components.Schemas.CreateAgenticSystemRequest) async throws -> Components.Schemas.AgenticSystemCreateResponse
  
  func createSession(request: Components.Schemas.CreateAgenticSystemSessionRequest) async throws -> Components.Schemas.AgenticSystemSessionCreateResponse
  
  func createTurn(request: Components.Schemas.CreateAgenticSystemTurnRequest) async throws -> AsyncStream<Components.Schemas.AgenticSystemTurnResponseStreamChunk>
}
