import Foundation
import OpenAPIRuntime

public class CustomTools {
  
  public class func getCreateEventTool() -> Components.Schemas.FunctionCallToolDefinition {
    return Components.Schemas.FunctionCallToolDefinition(
      description: "Create a calendar event",
      function_name: "create_event",
      parameters: Components.Schemas.FunctionCallToolDefinition.parametersPayload(
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
      _type: .function_call
    )
  }
}
