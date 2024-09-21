import Foundation

import LLaMARunner

class RunnerHolder: ObservableObject {
  var runner: Runner?
}

public class LocalInferenceService: InferenceService {
  private var runnerHolder = RunnerHolder()

  public init () {}

  public func loadModel(modelPath: String, tokenizerPath: String, completion: @escaping (Result<Void, Error>) -> Void) {
    runnerHolder.runner = runnerHolder.runner ?? Runner(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath
    )

    Task {
      let runner = runnerHolder.runner
      do {
        try runner!.load()
        completion(.success(()))
      } catch let loadError {
        completion(.failure(loadError))
      }
    }
  }

  public func chatCompletion(request: Components.Schemas.ChatCompletionRequest) -> AsyncStream<Components.Schemas.ChatCompletionResponseStreamChunk> {

    return AsyncStream { continuation in
      Task {
        do {
          var tokens: [String] = []

          let prompt = try encodeDialogPrompt(messages: prepareMessages(request: request))
          var stopReason: Components.Schemas.StopReason? = nil
          var buffer = ""
          var ipython = false

          try self.runnerHolder.runner?.generate(prompt, sequenceLength: 4096) { token in
            print("token: [" + token + "]\n")
            buffer += token
            tokens.append(token)

            if !ipython && buffer.starts(with: "<|python_tag|>") {
              ipython = true
              continuation.yield(
                Components.Schemas.ChatCompletionResponseStreamChunk(
                  event: Components.Schemas.ChatCompletionResponseEvent(
                    delta: .ToolCallDelta(Components.Schemas.ToolCallDelta(
                      content: .case1(""),
                      parse_status: Components.Schemas.ToolCallParseStatus.started
                      )
                    ),
                    event_type: .progress
                  )
                )
              )

              buffer = String(buffer.dropFirst("<|python_tag|>".count))
            }

            // TODO: Non-streaming lobprobs

            var text = ""
            if token == "<|eot_id|>" {
              stopReason = Components.Schemas.StopReason.end_of_turn
            } else if token == "<|eom_id|>" {
              stopReason = Components.Schemas.StopReason.end_of_message
            } else {
              text = token
            }

            var delta: Components.Schemas.ChatCompletionResponseEvent.deltaPayload
            if ipython {
              delta = .ToolCallDelta(Components.Schemas.ToolCallDelta(
                content: .case1(text),
                parse_status: .in_progress
              ))
            } else {
              delta = .case1(text)
            }

            if stopReason == nil {
              continuation.yield(
                Components.Schemas.ChatCompletionResponseStreamChunk(
                  event: Components.Schemas.ChatCompletionResponseEvent(
                    delta: delta,
                    event_type: .progress
                  )
                )
              )
            }
          }

          if stopReason == nil {
            stopReason = Components.Schemas.StopReason.out_of_tokens
          }

          let message = decodeAssistantMessage(tokens: tokens.joined(), stopReason: stopReason!)
          // TODO: non-streaming support

          let didParseToolCalls = message.tool_calls.count > 0
          if ipython && !didParseToolCalls {
            continuation.yield(
              Components.Schemas.ChatCompletionResponseStreamChunk(
                event: Components.Schemas.ChatCompletionResponseEvent(
                  delta: .ToolCallDelta(Components.Schemas.ToolCallDelta(content: .case1(""), parse_status: .failure)),
                  event_type: .progress
                )
                // TODO: why no stopReason?
              )
            )
          }

          for toolCall in message.tool_calls {
            continuation.yield(
              Components.Schemas.ChatCompletionResponseStreamChunk(
                event: Components.Schemas.ChatCompletionResponseEvent(
                  delta: .ToolCallDelta(Components.Schemas.ToolCallDelta(
                    content: .ToolCall(toolCall),
                    parse_status: .success
                  )),
                  event_type: .progress
                )
                // TODO: why no stopReason?
              )
            )
          }

          continuation.yield(
            Components.Schemas.ChatCompletionResponseStreamChunk(
              event: Components.Schemas.ChatCompletionResponseEvent(
                delta: .case1(""),
                event_type: .complete
              )
              // TODO: why no stopReason?
            )
          )
        }
      }
    }
  }
}
