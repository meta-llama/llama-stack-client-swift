import Foundation
import OpenAPIRuntime

public class CustomTools {
  
  // for chat completion (inference) tool calling
  public class func getCreateEventTool() -> Components.Schemas.ToolDefinition {
    return Components.Schemas.ToolDefinition(
      tool_name: Components.Schemas.ToolDefinition.tool_namePayload.case2( "create_event"),
      description: "Create a calendar event",
      parameters: Components.Schemas.ToolDefinition.parametersPayload(
        additionalProperties: [
          "event_name": Components.Schemas.ToolParamDefinition(
            param_type: "string",
            description: "The name of the meeting",
            required: true
          ),
          "start": Components.Schemas.ToolParamDefinition(
            param_type: "string",
            description: "Start date in yyyy-MM-dd HH:mm format, eg. '2024-01-01 13:00'",
            required: true
          ),
          "end": Components.Schemas.ToolParamDefinition(
            param_type: "string",
            description: "End date in yyyy-MM-dd HH:mm format, eg. '2024-01-01 14:00'",
            required: true
          )
        ]
      )
    )
  }
  
  // for agent tool calling
  public class func getCreateEventToolForAgent() -> Components.Schemas.ToolDef {
    return Components.Schemas.ToolDef(
      name: "create_event",
      description: "Create a calendar event",
      parameters: [
        Components.Schemas.ToolParameter(
            name: "event_name",
            parameter_type: "string",
            description: "The name of the meeting",
            required: true),
        Components.Schemas.ToolParameter(
            name: "start",
            parameter_type: "string",
            description: "Start date in yyyy-MM-dd HH:mm format, eg. '2024-01-01 13:00'",
            required: true),
        Components.Schemas.ToolParameter(
            name: "end",
            parameter_type: "string",
            description: "End date in yyyy-MM-dd HH:mm format, eg. '2024-01-01 14:00'",
            required: true)
      ],
      metadata: nil
    )
  }
}
