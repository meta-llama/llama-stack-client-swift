import Foundation
import OpenAPIRuntime

public class CustomTools {
  
  public class func getCreateEventTool() -> Components.Schemas.ToolDefinition {
    return Components.Schemas.ToolDefinition(
      description: "Create a calendar event",
      parameters: Components.Schemas.ToolDefinition.parametersPayload(
        additionalProperties: [
          "event_name": Components.Schemas.ToolParamDefinition(
            description: "The name of the meeting",
            param_type: "string",
            required: true
          ),
          "start": Components.Schemas.ToolParamDefinition(
            description: "Start date in yyyy-MM-dd HH:mm format, eg. '2024-01-01 13:00'",
            param_type: "string",
            required: true
          ),
          "end": Components.Schemas.ToolParamDefinition(
            description: "End date in yyyy-MM-dd HH:mm format, eg. '2024-01-01 14:00'",
            param_type: "string",
            required: true
          ),
        ]
      ),
      tool_name: Components.Schemas.ToolDefinition.tool_namePayload.case2( "create_event")

    )
  }
}
