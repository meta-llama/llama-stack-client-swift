/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import SwiftUI
import LlamaStackClient

struct ContentView: View {
  @State private var message: String = ""
  @State private var userInput: String = "Best quotes in Godfather"

  let imageUrl1 = "https://raw.githubusercontent.com/meta-llama/llama-models/refs/heads/main/Llama_Repo.jpeg"
  let imageUrl2 = "https://raw.githubusercontent.com/meta-llama/llama3/refs/heads/main/Llama3_Repo.jpeg"
  
  private let runnerQueue = DispatchQueue(label: "org.llamastack.iosquickdemo")
  
  var body: some View {
    VStack(spacing: 20) {
      ScrollView {
        Text(message.isEmpty ? "Click a button to ask Llama" : message)
          .font(.headline)
          .foregroundColor(.blue)
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color.gray.opacity(0.2))
          .cornerRadius(8)
      }
      .frame(maxHeight: 500)

      TextField("Your question or ask", text: $userInput)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding()
      
      AsyncImage(url: URL(string: imageUrl1)) { phase in
        switch phase {
        case .empty:
            ProgressView()
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .failure:
            Image(systemName: "llama")
                .resizable()
                .aspectRatio(contentMode: .fit)
        @unknown default:
            EmptyView()
        }
      }
      
      AsyncImage(url: URL(string: imageUrl2)) { phase in
          switch phase {
          case .empty:
              ProgressView()
          case .success(let image):
              image
                  .resizable()
                  .aspectRatio(contentMode: .fit)
          case .failure:
              Image(systemName: "llama")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
          @unknown default:
              EmptyView()
          }
      }
    .frame(height: 200)
      HStack {
        Button(action: {
          handleButtonClick(buttonName: "Text")
        }) {
          Text("Text")
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(8)
        }
        
        Button(action: {
          handleButtonClick(buttonName: "Image")
        }) {
          Text("Image")
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(8)
        }
        
        Button(action: {
          handleButtonClick(buttonName: "TextMultiImage")
        }) {
          Text("Text MultiImage")
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(8)
        }
      }
      Spacer()
    }
    .padding()
  }
  
  private func userMessageWithText(_ text: String) -> Components.Schemas.UserMessage {
    return Components.Schemas.UserMessage(
      role: .user,
      content:
        .case1(text)
    )
  }
  
  private func userMessageToDescribeAnImage(_ imageURL1: String) -> Components.Schemas.UserMessage {
    return Components.Schemas.UserMessage(
      role: .user,
      content:
        .InterleavedContentItem(
          .image(Components.Schemas.ImageContentItem(
            _type: .image,
            image: Components.Schemas.ImageContentItem.imagePayload( url: Components.Schemas.URL(uri: imageURL1))
            )
          )
      )
    )
  }
  
  private func userMessageWithTextAndMultiImage(_ text: String, _ imageURL1: String, _ imageURL2: String) -> Components.Schemas.UserMessage {
    return Components.Schemas.UserMessage(
      role: .user,
      content:
        .case3([
          Components.Schemas.InterleavedContentItem.text(
            Components.Schemas.TextContentItem(
              _type: .text,
              text: text
            )
          ),
          Components.Schemas.InterleavedContentItem.image(
            Components.Schemas.ImageContentItem(
              _type: .image,
              image: Components.Schemas.ImageContentItem.imagePayload( url: Components.Schemas.URL(uri: imageURL1))
              )
            ),
          Components.Schemas.InterleavedContentItem.image(
            Components.Schemas.ImageContentItem(
              _type: .image,
              image: Components.Schemas.ImageContentItem.imagePayload( url: Components.Schemas.URL(uri: imageURL2))
              )
            )
          ])
        )
  }
  
  private func handleButtonClick(buttonName: String) {
    if (buttonName == "Text" || buttonName == "TextImage") {
      if userInput.isEmpty {
        message = "Please enter your question or ask first."
        return
      }
    }
    
    var userMessage : Components.Schemas.UserMessage!
    if (buttonName == "Text") {
      userMessage = userMessageWithText(userInput)
    }
    else if (buttonName == "Image") {
      userMessage = userMessageToDescribeAnImage(imageUrl1)
    }
    else if (buttonName == "TextMultiImage") {
      userMessage = userMessageWithTextAndMultiImage(userInput, imageUrl1, imageUrl2)
    }
    
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    
    message = ""

    let workItem = DispatchWorkItem {
      defer {
        DispatchQueue.main.async {
        }
      }

      Task {
        // Llama 4 is not available in API providers' distro yet. To use Llama 4, you need to build llama-stack server from local https://github.com/meta-llama/llama-stack-client-swift/tree/latest-release/examples/ios_quick_demo#build-and-run-the-ios-demo
        let inference = RemoteInference(url: URL(string: "http://localhost:8321")!)
        do {
          for await chunk in try await inference.chatCompletion(
            request:
              Components.Schemas.ChatCompletionRequest(
                model_id:
                  //"meta-llama/Llama-3.1-8B-Instruct", // text-only Llama model
                  "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8", // Llama4 with text and image capability
                messages: [
                  .user(userMessage)
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
        }
        catch {
          print("Error: \(error)")
        }
      }
    }

    runnerQueue.async(execute: workItem)
  }
}
