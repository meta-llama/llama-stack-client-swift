import Foundation

func convertToNativeSwiftType(_ value: Any) -> Any {
    switch value {
    case let number as NSNumber:
        // Check if the number is actually a bool
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return number.boolValue
        }
        // Check if it's an integer
        if floor(number.doubleValue) == number.doubleValue {
            return number.intValue
        }
        return number.doubleValue
    case let string as String:
        return string
    case let array as [Any]:
        return array.map(convertToNativeSwiftType)
    case let dict as [String: Any]:
        return dict.mapValues(convertToNativeSwiftType)
    case is NSNull:
        return NSNull()
    default:
        return value // For any other types, return as is
    }
}

public class SystemDefaultGenerator {
  public init() {}
  
  public func gen() -> PromptTemplate {
    let templateStr = """
            Cutting Knowledge Date: December 2023
            Today Date: {{ today }}
            """
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMMM yyyy"
    
    return PromptTemplate(
      template: templateStr,
      data: ["today": dateFormatter.string(from: Date())]
    )
  }
}


public class FunctionTagCustomToolGenerator {
  public init() {}
  
  public func gen(customTools: [Components.Schemas.ToolDefinition]) throws -> PromptTemplate {
    let templateStr = """
            You have access to the following functions:
            
            {% for t in custom_tools %}
            Use the function '{{ t.tool_name }}' to '{{ t.description }}':
            {"name": "{{t.tool_name}}", "description": "{{t.description}}", "parameters": {{t.parameters}}}
            
            {% endfor -%}
            Think very carefully before calling functions.
            If you choose to call a function ONLY reply in the following format with no prefix or suffix:
            
            <function=example_function_name>{"example_name": "example_value"}</function>
            
            Reminder:
            - If looking for real time information use relevant functions before falling back to brave_search
            - Function calls MUST follow the specified format, start with <function= and end with </function>
            - Required parameters MUST be specified
            - Only call one function at a time
            - Put the entire function call reply on one line
            """
    
    let encoder = JSONEncoder()
    return PromptTemplate(
      template: templateStr,
      data: ["custom_tools": try customTools.map {
        let data = try encoder.encode($0)
        let obj = try JSONSerialization.jsonObject(with: data)
        return convertToNativeSwiftType(obj)
      }]
    )
  }
}
