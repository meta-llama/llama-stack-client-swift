import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public extension Components.Schemas.ChatCompletionRequest.messagesPayloadPayload {
  func toAgenticSystemTurnCreateRequest() -> Components.Schemas.CreateAgenticSystemTurnRequest.messagesPayloadPayload? {
    switch self {
    case .UserMessage(let userMessage):
      return .UserMessage(userMessage)
    case .ToolResponseMessage(let toolResponseMessage):
      return .ToolResponseMessage(toolResponseMessage)
    case .SystemMessage, .CompletionMessage:
      return nil
    }
  }
}

public extension Components.Schemas.CreateAgenticSystemTurnRequest.messagesPayloadPayload {
  func toChatCompletionRequest() -> Components.Schemas.ChatCompletionRequest.messagesPayloadPayload {
    switch self {
    case .UserMessage(let userMessage):
      return .UserMessage(userMessage)
    case .ToolResponseMessage(let toolResponseMessage):
      return .ToolResponseMessage(toolResponseMessage)
    }
  }
  
  func toAgenticSystemTurnCreateRequest() -> Components.Schemas.Turn.input_messagesPayloadPayload {
    switch self {
    case .UserMessage(let userMessage):
      return .UserMessage(userMessage)
    case .ToolResponseMessage(let toolResponseMessage):
      return .ToolResponseMessage(toolResponseMessage)
    }
  }
}

public extension Components.Schemas.AgentConfig.toolsPayloadPayload {
  func toToolDefinition() -> Components.Schemas.ToolDefinition {
    switch self {
    case .SearchToolDefinition(_):
      return Components.Schemas.ToolDefinition(
        tool_name: .BuiltinTool(.brave_search)
      )
    case .WolframAlphaToolDefinition(_):
      return Components.Schemas.ToolDefinition(
        tool_name: .BuiltinTool(.wolfram_alpha)
      )
    case .PhotogenToolDefinition(_):
      return Components.Schemas.ToolDefinition(
        tool_name: .BuiltinTool(.photogen)
      )
    case .CodeInterpreterToolDefinition(_):
      return Components.Schemas.ToolDefinition(
        tool_name: .BuiltinTool(.code_interpreter)
      )
    case .FunctionCallToolDefinition(let tool):
      return Components.Schemas.ToolDefinition(
        description: tool.description,
        parameters: tool.parameters.toToolDefinitionParameters(),
        tool_name: .case2(tool.function_name)
      )
    case .case6(let value):
      return Components.Schemas.ToolDefinition(
        description: "Memory Tool",
        parameters: nil,
        tool_name: .case2("memory")
      )
    }
  }
}

public extension Components.Schemas.AgentConfig {
  var toolDefinitions: [Components.Schemas.ToolDefinition]? {
    return tools?.map { $0.toToolDefinition() }
  }
}

public extension Components.Schemas.FunctionCallToolDefinition.parametersPayload {
    func toToolDefinitionParameters() -> Components.Schemas.ToolDefinition.parametersPayload {
        return Components.Schemas.ToolDefinition.parametersPayload(additionalProperties: self.additionalProperties)
    }
}

public extension Components.Schemas.ToolDefinition.parametersPayload {
    init(fromFunctionCallParameters params: Components.Schemas.FunctionCallToolDefinition.parametersPayload) {
        self.init(additionalProperties: params.additionalProperties)
    }
}