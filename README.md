# llama-stack-client-swift

[![Discord](https://img.shields.io/discord/1257833999603335178)](https://discord.gg/TZAAYNVtrU)

llama-stack-client-swift brings the inference and agents APIs of [Llama Stack](https://github.com/meta-llama/llama-stack) to iOS.

## Features

- **Inference & Agents:** Leverage remote Llama Stack distributions for inference, code execution, and safety.
- **Custom Tool Calling:**  Provide Swift tools that Llama agents can understand and use.

## Installation

1. Xcode > File > Add Package Dependencies...

2. Add this repo URL at the top right: `https://github.com/meta-llama/llama-stack-client-swift`

3. Select and add `llama-stack-client-swift` to your app target

4. On the first build: Enable & Trust the OpenAPIGenerator extension when prompted

5. `import LlamaStackClient` and test out a call:

```swift
import LlamaStackClient
let inference = RemoteInferenceProvider(url: URL(string: "http://127.0.0.1:5000")!)
    for await chunk in try await inference.chatCompletion(
        request:
            Components.Schemas.ChatCompletionRequest(
            messages: [
                .UserMessage(Components.Schemas.UserMessage(
                    content: .case1("Hello Llama!"),
                    role: .user)
                )
            ], model: "Meta-Llama3.1-8B-Instruct",
            stream: true)
        ) {
        switch (chunk.event.delta) {
        case .case1(let s):
            print(s)
        case .ToolCallDelta(_):
            break
        }
    }
```
