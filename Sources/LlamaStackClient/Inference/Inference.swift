import Foundation

public protocol Inference {
  /* Start with chatCompletion for now */

  // func completion(request: CompletionRequest) async throws -> AsyncStream<CompletionChunkOrResponse>
  func chatCompletion(request: Components.Schemas.ChatCompletionRequest) async throws -> AsyncStream<Components.Schemas.ChatCompletionResponseStreamChunk>
  // func batchCompletion(request: BatchCompletionRequest) async throws -> BatchCompletionResponse
  // func batchChatCompletion(request: BatchChatCompletionRequest) async throws -> BatchChatCompletionResponse
}
