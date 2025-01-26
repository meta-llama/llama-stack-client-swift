import Foundation
import OpenAPIRuntime


class ChatAgent {
  private let agentConfig: Components.Schemas.AgentConfig
  private let inferenceApi: Inference
  private var sessions: [String: Components.Schemas.Session]

  init(
    agentConfig: Components.Schemas.AgentConfig,
    inferenceApi: Inference
  ) {
    self.agentConfig = agentConfig
    self.inferenceApi = inferenceApi
    self.sessions = [:]
  }

  public func createSession(name: String) -> Components.Schemas.Session {
    let sessionId = UUID().uuidString

    let session = Components.Schemas.Session(
      session_id: sessionId,
      session_name: name,
      started_at: Date(),
      turns: []
    )

    sessions[sessionId] = session

    return session
  }

  public func createAndExecuteTurn(agent_id: String, session_id: String, request: Components.Schemas.CreateAgentTurnRequest) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    return AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> { continuation in
      Task {
        let session = sessions[session_id]
        let turnId = UUID().uuidString
        let startTime = Date()

        continuation.yield(
          Components.Schemas.AgentTurnResponseStreamChunk(event: Components.Schemas.AgentTurnResponseEvent(payload:
                .turn_start(Components.Schemas.AgentTurnResponseTurnStartPayload(
                event_type: .turn_start,
                turn_id: turnId
              ))
          ))
        )
      }
    }
  }

  public func run(
    session: Components.Schemas.Session,
    turnId: String,
    inputMessages: [Components.Schemas.Message],
    attachments: [Components.Schemas.Turn.output_attachmentsPayload],
    samplingParams: Components.Schemas.SamplingParams?,
    stream: Bool = false
  ) -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    return AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> { continuation in
      Task {
        do {
          for try await chunk in try await inferenceApi.chatCompletion(
            request: Components.Schemas.ChatCompletionRequest(
              messages: inputMessages,
              model_id: agentConfig.model,
              stream: true,
              tools: [] //agentConfig.client_tools
            )
          ) {
              continuation.yield(
                Components.Schemas.AgentTurnResponseStreamChunk(
                  event: Components.Schemas.AgentTurnResponseEvent(
                    payload:
                        .step_progress(
                          Components.Schemas.AgentTurnResponseStepProgressPayload(
                            delta: chunk.event.delta,
                            event_type: .step_progress,
                            step_id: UUID().uuidString,
                            step_type: .inference
                          )
                        )
                  )
                )
              )
          }
          continuation.finish()
        } catch {
          print("Error occurred: \(error)")
        }
      }
    }
  }
}
