# llama-stack-client-swift

[![Discord](https://img.shields.io/discord/1257833999603335178)](https://discord.gg/llama-stack)

llama-stack-client-swift brings the inference and agents APIs of [Llama Stack](https://github.com/meta-llama/llama-stack) to iOS.

## Features

- **Inference & Agents:** Leverage remote Llama Stack distributions for inference, code execution, and safety.
- **Custom Tool Calling:**  Provide Swift tools that Llama agents can understand and use.

## Quick Demo
See [here](https://github.com/meta-llama/llama-stack-apps/tree/ios_demo/examples/ios_quick_demo/iOSQuickDemo) for a complete iOS demo ([video](https://drive.google.com/file/d/1HnME3VmsYlyeFgsIOMlxZy5c8S2xP4r4/view?usp=sharing)) using a remote Llama Stack server for inferencing.

## Installation

1. Click "Xcode > File > Add Package Dependencies...".

2. Add this repo URL at the top right: `https://github.com/meta-llama/llama-stack-client-swift`.

3. Select and add `llama-stack-client-swift` to your app target.

4. On the first build: Enable & Trust the OpenAPIGenerator extension when prompted.

5. Set up a remote Llama Stack distributions, assuming you have a [Fireworks](https://fireworks.ai/account/api-keys) or [Together](https://api.together.ai/) API key, which you can get easily by clicking the link:

```
conda create -n llama-stack python=3.10
conda activate llama-stack
pip install llama-stack=0.1.0
```
Then, either:
```
llama stack build --template fireworks --image-type conda
export FIREWORKS_API_KEY="<your_fireworks_api_key>"
llama stack run fireworks
```
or
```
llama stack build --template together --image-type conda
export TOGETHER_API_KEY="<your_together_api_key>"
llama stack run together
```

The default port is 5000 for `llama stack run` and you can specify a different port by adding `--port <your_port>` to the end of `llama stack run fireworks|together`.

6. Replace the `RemoteInference` url below with the your host IP and port:

```swift
import LlamaStackClient

let inference = RemoteInference(url: URL(string: "http://127.0.0.1:5000")!)

do {
    for await chunk in try await inference.chatCompletion(
    request:
        Components.Schemas.ChatCompletionRequest(
        messages: [
            .UserMessage(Components.Schemas.UserMessage(
            content: .case1(userInput),
            role: .user)
            )
        ], model_id: "meta-llama/Llama-3.1-8B-Instruct",
        stream: true)
    ) {
        switch (chunk.event.delta) {
        case .TextDelta(let s):
            print(s.text)
            break
        case .ImageDelta(let s):
            print("> \(s)")
            break
        case .ToolCallDelta(let s):
            print("> \(s)")
            break
        }
    }
}
catch {
    print("Error: \(error)")
}
```

### Syncing the API spec

Llama Stack `Types.swift` file is generated from the Llama Stack [API spec](https://github.com/meta-llama/llama-stack/blob/main/docs/resources/llama-stack-spec.yaml) in the main [Llama Stack repo](https://github.com/meta-llama/llama-stack). That spec is synced to this repo via a git submodule and script. You shouldn't need to run this, unless the API spec and your remote server get updated.

```
git submodule update --init --recursive
scripts/generate_swift_types.sh
```

This will update the `openapi.yaml` file in the Llama Stack Swift SDK source folder `Sources/LlamaStackClient`.

