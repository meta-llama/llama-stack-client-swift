import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public class LocalAgentsService: AgentsService {
  let inferenceService = LocalInferenceService()
  var agents: [String: ChatAgent] = [:]
  
  public init () {}
  
  public func loadModel(modelPath: String, tokenizerPath: String, completion: @escaping (Result<Void, Error>) -> Void) {
    inferenceService.loadModel(modelPath: modelPath, tokenizerPath: tokenizerPath) { result in
      switch result {
      case .success:
        completion(.success(()))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  public func create(request: Components.Schemas.CreateAgentRequest) async throws -> Components.Schemas.AgentCreateResponse {
    let agentId = UUID().uuidString
    let agent = ChatAgent(
      agentConfig: request.agent_config,
      inferenceApi: self.inferenceService
    )
    
    agents[agentId] = agent
    
    return Components.Schemas.AgentCreateResponse(agent_id: agentId)
  }
  
  public func createSession(request: Components.Schemas.CreateAgentSessionRequest) async throws -> Components.Schemas.AgentSessionCreateResponse {
    let agent = agents[request.agent_id]
    let session = agent!.createSession(name: request.session_name)
    return Components.Schemas.AgentSessionCreateResponse(
      session_id: session.session_id
    )
  }
  
  public func createTurn(request: Components.Schemas.CreateAgentTurnRequest) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    let agent = agents[request.agent_id]!
    return try await agent.createAndExecuteTurn(request: request)
  }
}
