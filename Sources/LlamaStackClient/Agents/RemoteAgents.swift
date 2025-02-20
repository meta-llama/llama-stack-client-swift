import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public class RemoteAgents: Agents {

  private let url: URL
  private let client: Client
  private let encoder = JSONEncoder()

  public init (url: URL, apiKey: String? = nil) {
    self.url = url
    self.client = Client(
      serverURL: url,
      transport: URLSessionTransport(),
      middlewares: apiKey.map { [BearerAuthenticationMiddleware(token: $0)] } ?? []
    )
  }

  // Example helper function
  public func initAndCreateTurn(
    messages: [Components.Schemas.CreateAgentTurnRequest.messagesPayloadPayload]
  ) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    let createSystemResponse = try await create(
      request: Components.Schemas.CreateAgentRequest(
        agent_config: Components.Schemas.AgentConfig(
          input_shields: ["llama_guard"],
          output_shields: ["llama_guard"],
          client_tools: [ CustomTools.getCreateEventToolForAgent() ],
          max_infer_iters: 1,
          model: "Meta-Llama3.1-8B-Instruct",
          instructions: "You are a helpful assistant",
          enable_session_persistence: false
        )
      )
    )
    let agentId = createSystemResponse.agent_id

    let createSessionResponse = try await createSession(
      agent_id: agentId, request: Components.Schemas.CreateAgentSessionRequest(session_name: "pocket-llama")
    )
    let agenticSystemSessionId = createSessionResponse.session_id

    let request = Components.Schemas.CreateAgentTurnRequest(
      messages: messages,
      stream: true
    )

    return try await createTurn(agent_id: agentId, session_id: agenticSystemSessionId, request: request)
  }

  public func create(request: Components.Schemas.CreateAgentRequest) async throws -> Components.Schemas.AgentCreateResponse {
    let response = try await client.post_sol_v1_sol_agents(body: Operations.post_sol_v1_sol_agents.Input.Body.json(request))
    return try response.ok.body.json
  }

  public func createSession(agent_id: String, request: Components.Schemas.CreateAgentSessionRequest) async throws -> Components.Schemas.AgentSessionCreateResponse {
    let response = try await client.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session(
      path: Operations.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session.Input.Path(agent_id: agent_id),
      headers: Operations.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session.Input.Headers.init(),
      body: Operations.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session.Input.Body.json(request))
    return try response.ok.body.json
  }

  public func createTurn(agent_id: String, session_id: String, request: Components.Schemas.CreateAgentTurnRequest) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    return AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> { continuation in
      Task {
        do {
          let response = try await self.client.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session_sol__lcub_session_id_rcub__sol_turn(
            path: Operations.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session_sol__lcub_session_id_rcub__sol_turn.Input.Path(agent_id: agent_id, session_id: session_id),
            headers: Operations.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session_sol__lcub_session_id_rcub__sol_turn.Input.Headers.init(),
            body: Operations.post_sol_v1_sol_agents_sol__lcub_agent_id_rcub__sol_session_sol__lcub_session_id_rcub__sol_turn.Input.Body.json(request))
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
