import Foundation
import OpenAPIRuntime


public class ChatAgent {
  private let agentConfig: Components.Schemas.AgentConfig
  private let inferenceApi: Inference
  private var sessions: [String: Components.Schemas.Session]

  public init(
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
      turns: [],
      started_at: Date()
    )

    sessions[sessionId] = session

    return session
  }

  public func createAndExecuteTurn(agent_id: String, session_id: String, request: Components.Schemas.CreateAgentTurnRequest)  -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
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
        
        // Build out step history
        let steps: [Components.Schemas.Turn.stepsPayloadPayload] = []
        var outputMessage: Components.Schemas.CompletionMessage? = nil
        for await chunk: Components.Schemas.AgentTurnResponseStreamChunk in self.run(
          session: session!,
          turnId: turnId,
          inputMessages: request.messages.map { $0.toMessage()! },
          attachments: [], // TODO: request.documents ??
          samplingParams: agentConfig.sampling_params
        ) {
          let payload = chunk.event.payload
          switch (payload) {
          case .step_start(_):
            break
          case .step_progress(_):
            break
          case .step_complete(let step):
            switch (step.step_details) {
            case .inference(let step):
              outputMessage = step.model_response
            case .tool_execution(_):
              break
            case .shield_call(_):
              break
            case .memory_retrieval(_):
              break
            }
          case .turn_start(_):
            break
          case .turn_complete(_):
            break
          case .turn_awaiting_input(_):
            break
          }
          continuation.yield(chunk)
        }
        let turn = Components.Schemas.Turn(
          turn_id: turnId,
          session_id: session_id,
          input_messages: request.messages.map { $0.toAgenticSystemTurnCreateRequest() },
          steps: steps,
          output_message: outputMessage!,
          started_at: Date()
        )
        await MainActor.run {
          var s = self.sessions[session_id]
          s!.turns.append(turn)
        }
        
        continuation.yield(
          Components.Schemas.AgentTurnResponseStreamChunk(
            event: Components.Schemas.AgentTurnResponseEvent(
              payload:
                  .turn_complete(Components.Schemas.AgentTurnResponseTurnCompletePayload(
                    event_type: .turn_complete,
                    turn: turn))
            )
          )
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
    return AsyncStream { continuation in
      Task {
        do {
          for try await chunk: Components.Schemas.ChatCompletionResponseStreamChunk in try await inferenceApi.chatCompletion(
            request: Components.Schemas.ChatCompletionRequest(
              model_id: agentConfig.model,
              messages: inputMessages,
              tools: [], //agentConfig.client_tools
              stream: true
            )
          ) {
              continuation.yield(
                Components.Schemas.AgentTurnResponseStreamChunk(
                  event: Components.Schemas.AgentTurnResponseEvent(
                    payload:
                        .step_progress(
                          Components.Schemas.AgentTurnResponseStepProgressPayload(
                            event_type: .step_progress,
                            step_type: .inference,
                            step_id: UUID().uuidString,
                            delta: chunk.event.delta
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
