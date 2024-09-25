import Foundation

public class LlamaStackDistribution {
  
  public let inference: Inference?
  public let agents: Agents?
  
  public init(
    inference: Inference?,
    agents: Agents?
  ) {
    self.inference = inference
    self.agents = agents
  }
}
