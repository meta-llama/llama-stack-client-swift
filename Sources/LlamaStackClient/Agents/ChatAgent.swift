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
      started_at: Date(),
      turns: []
    )

    sessions[sessionId] = session

    return session
  }

  public func createAndExecuteTurn(request: Components.Schemas.CreateAgentTurnRequest) async throws -> AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> {
    return AsyncStream<Components.Schemas.AgentTurnResponseStreamChunk> { continuation in
      Task {
        let session = sessions[request.session_id]
        let turnId = UUID().uuidString
        let startTime = Date()

        continuation.yield(
          Components.Schemas.AgentTurnResponseStreamChunk(event: Components.Schemas.AgentTurnResponseEvent(payload:
              .AgentTurnResponseTurnStartPayload(Components.Schemas.AgentTurnResponseTurnStartPayload(
                event_type: .turn_start,
                turn_id: turnId
              ))
          ))
        )

        // TODO: Build out step history
        let steps: [Components.Schemas.Turn.stepsPayloadPayload] = []
        var outputMessage: Components.Schemas.CompletionMessage? = nil

        for await chunk in self.run(
          session: session!,
          turnId: turnId,
          inputMessages: request.messages.map { $0.toChatCompletionRequest() },
          attachments: request.attachments ?? [],
          samplingParams: agentConfig.sampling_params
        ) {
          let payload = chunk.event.payload
          switch (payload) {
          case .AgentTurnResponseStepStartPayload(_):
            break
          case .AgentTurnResponseStepProgressPayload(_):
            break
          case .AgentTurnResponseStepCompletePayload(let step):
            switch (step.step_details) {
            case .InferenceStep(let step):
              outputMessage = step.model_response
            case .ToolExecutionStep(_):
              break
            case .ShieldCallStep(_):
              break
            case .MemoryRetrievalStep(_):
              break
            }
          case .AgentTurnResponseTurnStartPayload(_):
            break
          case .AgentTurnResponseTurnCompletePayload(_):
            break
          }

          continuation.yield(chunk)
        }

        let turn = Components.Schemas.Turn(
          input_messages: request.messages.map { $0.toAgenticSystemTurnCreateRequest() },
          output_attachments: [],
          output_message: outputMessage!,
          session_id: request.session_id,
          started_at: Date(),
          steps: steps,
          turn_id: turnId
        )

        await MainActor.run {
          var s = self.sessions[request.session_id]
          s!.turns.append(turn)
        }

        continuation.yield(
          Components.Schemas.AgentTurnResponseStreamChunk(
            event: Components.Schemas.AgentTurnResponseEvent(
              payload:
                  .AgentTurnResponseTurnCompletePayload(Components.Schemas.AgentTurnResponseTurnCompletePayload(
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
    inputMessages: [Components.Schemas.ChatCompletionRequest.messagesPayloadPayload],
    attachments: [Components.Schemas.Attachment],
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
              tools: agentConfig.toolDefinitions
            )
          ) {
            switch(chunk.event.delta) {
            case .case1(let s):
              continuation.yield(
                Components.Schemas.AgentTurnResponseStreamChunk(
                  event: Components.Schemas.AgentTurnResponseEvent(
                    payload:
                        .AgentTurnResponseStepProgressPayload(
                          Components.Schemas.AgentTurnResponseStepProgressPayload(
                            event_type: .step_progress,
                            model_response_text_delta: s,
                            step_id: UUID().uuidString,
                            step_type: .inference
                          )
                        )
                  )
                )
              )
            case .ToolCallDelta(let toolDelta):
              continuation.yield(
                Components.Schemas.AgentTurnResponseStreamChunk(
                  event: Components.Schemas.AgentTurnResponseEvent(
                    payload:
                        .AgentTurnResponseStepProgressPayload(
                          Components.Schemas.AgentTurnResponseStepProgressPayload(
                            event_type: .step_progress,
                            step_id: UUID().uuidString,
                            step_type: .inference,
                            tool_call_delta: toolDelta
                          )
                        )
                  )
                )
              )
            }
          }
        } catch {
          print("Error occurred: \(error)")
        }
      }
    }
  }
}
