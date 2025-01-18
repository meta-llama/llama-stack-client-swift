import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public class LocalAgents: Agents {
  let inference: Inference
  var agents: [String: ChatAgent] = [:]

  public init (inference: Inference) {
    self.inference = inference
  }

  // Example helper function
  public func initAndCreateTurn(
    messages: [Components.Schemas.CreateAgentTurnRequest.messagesPayloadPayload]
  ) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    let createSystemResponse = try await create(
      request: Components.Schemas.CreateAgentRequest(
        agent_config: Components.Schemas.AgentConfig(
          enable_session_persistence: false,
          input_shields: [],
          instructions: "You are a helpful assistant",
          max_infer_iters: 1,
          model: "Meta-Llama3.1-8B-Instruct",
          output_shields: []
//          tools: [
//            Components.Schemas.AgentConfig.toolsPayloadPayload.FunctionCallToolDefinition(
//              CustomTools.getCreateEventTool()
//              )
//          ]
        )
      )
    )
    let agentId = createSystemResponse.agent_id

    let createSessionResponse = try await createSession(agent_id: agentId,
      request: Components.Schemas.CreateAgentSessionRequest(session_name: "pocket-llama")
    )
    let agenticSystemSessionId = createSessionResponse.session_id

    let request = Components.Schemas.CreateAgentTurnRequest(
      messages: messages,
      stream: true
    )

    return try await createTurn(agent_id: agentId, session_id: agenticSystemSessionId, request: request)
  }

  public func create(request: Components.Schemas.CreateAgentRequest) async throws -> Components.Schemas.AgentCreateResponse {
    let agentId = UUID().uuidString
    let agent = ChatAgent(
      agentConfig: request.agent_config,
      inferenceApi: self.inference
    )

    agents[agentId] = agent

    return Components.Schemas.AgentCreateResponse(agent_id: agentId)
  }

  public func createSession(agent_id: String, request: Components.Schemas.CreateAgentSessionRequest) async throws -> Components.Schemas.AgentSessionCreateResponse {
    let agent = agents[agent_id]
    let session = agent!.createSession(name: request.session_name)
    return Components.Schemas.AgentSessionCreateResponse(
      session_id: session.session_id
    )
  }

  public func createTurn(agent_id: String, session_id: String, request: Components.Schemas.CreateAgentTurnRequest) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    let agent = agents[agent_id]!
    return try await agent.createAndExecuteTurn(agent_id: agent_id, session_id: session_id, request: request)
  }
}
