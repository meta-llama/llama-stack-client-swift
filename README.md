# llama-stack-client-swift

[![Discord](https://img.shields.io/discord/1257833999603335178)](https://discord.gg/llama-stack)

llama-stack-client-swift brings the inference and agents APIs of [Llama Stack](https://github.com/meta-llama/llama-stack) to iOS.

**Update: February 18, 2025** The llama-stack-client-swift SDK version has been updated to 0.1.3, working with Llama Stack 0.1.3 ([release note](https://github.com/meta-llama/llama-stack/releases/tag/v0.1.3)).

## Features

- **Inference & Agents:** Leverage remote Llama Stack distributions for inference, code execution, and safety.
- **Custom Tool Calling:**  Provide Swift tools that Llama agents can understand and use.

## iOS Demos
See [here](https://github.com/meta-llama/llama-stack-apps/tree/main/examples/ios_quick_demo) for a quick iOS demo ([video](https://drive.google.com/file/d/1HnME3VmsYlyeFgsIOMlxZy5c8S2xP4r4/view?usp=sharing)) using a remote Llama Stack server for inferencing.

For a more advanced demo using the Llama Stack Agent API and custom tool calling feature, see the [iOS Calendar Assistant demo](https://github.com/meta-llama/llama-stack-apps/tree/main/examples/ios_calendar_assistant).


## Installation

1. Click "Xcode > File > Add Package Dependencies...".

2. Add this repo URL at the top right: `https://github.com/meta-llama/llama-stack-client-swift` and 0.1.3 in the Dependency Rule, then click Add Package.

3. Select and add `llama-stack-client-swift` to your app target.

4. On the first build: Enable & Trust the OpenAPIGenerator extension when prompted.

5. The quickest way to try out the demo for remote inference is using Together.ai's Llama Stack distro at https://llama-stack.together.ai - you can skip Step 6 unless you want to build your own distro. 

6. (Optional) Set up a remote Llama Stack distributions, assuming you have a [Fireworks](https://fireworks.ai/account/api-keys) or [Together](https://api.together.ai/) API key, which you can get easily by clicking the link:

```
conda create -n llama-stack python=3.10
conda activate llama-stack
pip install --no-cache llama-stack==0.1.3 llama-models==0.1.3 llama-stack-client==0.1.3
```

Then, either:
```
PYPI_VERSION=0.1.3 llama stack build --template fireworks --image-type conda
export FIREWORKS_API_KEY="<your_fireworks_api_key>"
llama stack run fireworks
```
or
```
PYPI_VERSION=0.1.3 llama stack build --template together --image-type conda
export TOGETHER_API_KEY="<your_together_api_key>"
llama stack run together
```

The default port is 5000 for `llama stack run` and you can specify a different port by adding `--port <your_port>` to the end of `llama stack run fireworks|together`.

Replace the `RemoteInference` url string below with the host IP and port of the remote Llama Stack distro in Step 6:

```swift
import LlamaStackClient

let inference = RemoteInference(url: URL(string: "https://llama-stack.together.ai")!)
```

7. Build and Run the iOS demo.

Below is an example code snippet to use the Llama Stack inference API. See the iOS Demos above for complete code.

```swift
for await chunk in try await inference.chatCompletion(
    request:
        Components.Schemas.ChatCompletionRequest(
        model_id: "meta-llama/Llama-3.1-8B-Instruct",
        messages: [
            .user(
            Components.Schemas.UserMessage(
                role: .user,
                content:
                    .InterleavedContentItem(
                        .text(Components.Schemas.TextContentItem(
                            _type: .text,
                            text: userInput
                        )
                    )
                )
            )
        )
        ],
        stream: true)
    ) {
        switch (chunk.event.delta) {
        case .text(let s):
            message += s.text
            break
        case .image(let s):
            print("> \(s)")
            break
        case .tool_call(let s):
            print("> \(s)")
            break
        }
    }
```
