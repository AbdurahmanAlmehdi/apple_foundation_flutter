// AppleFoundationFlutterPlugin.swift
// Full improved implementation
// Requires: Xcode 17 / iOS 18 SDK (FoundationModels framework)

import Flutter
import UIKit

// Only attempt to import and use FoundationModels if on iOS 18+
#if canImport(FoundationModels)
  import FoundationModels
#endif

@available(iOS 26.0, *)
actor SessionStore {
  private var sessions: [String: LanguageModelSession] = [:]

  subscript(id: String) -> LanguageModelSession? {
    get { sessions[id] }
    set { sessions[id] = newValue }
  }

  func insert(_ session: LanguageModelSession, for id: String) {
    sessions[id] = session
  }

  func remove(_ id: String) {
    sessions[id] = nil
  }

  func cancelAll() {
    // The sessions will be deallocated and their tasks cancelled automatically.
    sessions.removeAll()
  }
}

@available(iOS 26.0, *)
public final class AppleFoundationFlutterPlugin: NSObject, FlutterPlugin {

  private var store: Any?
  private lazy var channelName = "apple_foundation_flutter"
  private var cachedAvailability: FlutterError?

  override init() {
    super.init()
    if #available(iOS 26.0, *) {
      store = SessionStore()
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "apple_foundation_flutter",
      binaryMessenger: registrar.messenger())
    let instance = AppleFoundationFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  deinit {
    if #available(iOS 26.0, *), let store = self.store as? SessionStore {
      Task { await store.cancelAll() }
    }
  }

  private func checkAvailability() -> FlutterError? {
    if let cached = cachedAvailability { return cached }

    #if os(iOS)
      if #available(iOS 26.0, *) {
        let status = SystemLanguageModel.default.availability
        switch status {
        case .available:
          return nil
        case .unavailable(let reason):
          let error = FlutterError(
            code: reason.flutterCode,
            message: reason.flutterMessage,
            details: nil)
          cachedAvailability = error
          return error
        @unknown default:
          let error = FlutterError(
            code: "UNKNOWN_UNAVAILABILITY",
            message: "The language model is unavailable for an unknown reason.",
            details: nil)
          cachedAvailability = error
          return error
        }
      } else {
        let error = FlutterError(
          code: "UNSUPPORTED_OS_VERSION",
          message: "Apple Foundation Models require iOS 26.0 or later.",
          details: nil)
        cachedAvailability = error
        return error
      }
    #else
      let error = FlutterError(
        code: "UNSUPPORTED_OS",
        message: "This plugin is only available on iOS.",
        details: nil)
      cachedAvailability = error
      return error
    #endif
  }

  private func generateSessionID() -> String { UUID().uuidString }

  @available(iOS 26.0, *)
  private func session(for id: String?, instructions: String? = nil) async -> LanguageModelSession {
    if let id = id, let existing = await (self.store as? SessionStore)?[id] {
      return existing
    }
    // If instructions are provided, create a new session with them.
    if let instructions = instructions {
      return LanguageModelSession(instructions: instructions)
    }
    return LanguageModelSession()
  }

  @available(iOS 26.0, *)
  private func options(from args: [String: Any]) -> GenerationOptions? {
    var opts = GenerationOptions()
    if let max = args["maxTokens"] as? Int { opts.maximumResponseTokens = max }
    if let temp = args["temperature"] as? Double { opts.temperature = temp }
    if let topP = args["topP"] as? Double {
      opts.sampling = .random(probabilityThreshold: topP)
    }
    return opts
  }

  private func complete(_ result: @escaping FlutterResult, with value: Any?) {
    Task { await MainActor.run { result(value) } }
  }

  private func complete(_ result: @escaping FlutterResult, error: Error) {
    let flutterError: FlutterError
    if #available(iOS 26.0, *), let genError = error as? LanguageModelSession.GenerationError {
      flutterError = FlutterError(
        code: "GENERATION_ERROR", message: genError.localizedDescription,
        details: genError.errorDescription)
    } else {
      flutterError =
        error as? FlutterError
        ?? FlutterError(
          code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil)
    }
    Task { await MainActor.run { result(flutterError) } }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Always handle these basic calls regardless of availability
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      return
    case "isAvailable":
      result(checkAvailability() == nil)
      return
    case "getAvailabilityStatus":
      if let err = checkAvailability() {
        result(["available": false, "reason": err.message ?? "unknown"])
      } else {
        result(["available": true, "reason": "Available"])
      }
      return
    default:
      break
    }

    // For all other methods, first verify that the FoundationModels are available.
    if let error = checkAvailability() {
      result(error)
      return
    }

    // We can now safely call methods that require iOS 18.
    if #available(iOS 26.0, *) {
      switch call.method {
      case "openSession": openSession(call, result)
      case "closeSession": closeSession(call, result)
      case "getModelCapabilities": getCapabilities(result)
      case "ask": ask(call, result)
      case "generateText": generateText(call, result)
      case "generateAlternatives": generateAlternatives(call, result)
      case "summarizeText": summarizeText(call, result)
      case "extractInformation": extractInformation(call, result)
      case "classifyText": classifyText(call, result)
      case "generateSuggestions": generateSuggestions(call, result)
      case "getStructuredData": getStructuredData(call, result)
      case "getListOfString": getListOfString(call, result)
      default: result(FlutterMethodNotImplemented)
      }
    } else {
      // This should not be reached due to the checkAvailability guard, but is here for safety.
      result(
        FlutterError(
          code: "UNSUPPORTED_OS_VERSION",
          message: "Apple Foundation Models require iOS 26.0 or later.",
          details: nil))
    }
  }

  @available(iOS 26.0, *)
  private func openSession(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let instructions = dict["instructions"] as? String
    else {
      complete(
        result,
        error: FlutterError(
          code: "INVALID_ARGUMENTS", message: "instructions missing", details: nil))
      return
    }
    let sessionID = generateSessionID()
    let session = LanguageModelSession(instructions: instructions)

    Task {
      if let store = self.store as? SessionStore {
        await store.insert(session, for: sessionID)
        complete(result, with: sessionID)
      }
    }
  }

  @available(iOS 26.0, *)
  private func closeSession(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let id = dict["sessionId"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "sessionId missing", details: nil))
      return
    }
    Task {
      if let store = self.store as? SessionStore {
        await store.remove(id)
        complete(result, with: nil)
      }
    }
  }

  @available(iOS 26.0, *)
  private func getCapabilities(_ result: @escaping FlutterResult) {
    let model = SystemLanguageModel.default
    let caps: [String: Any] = [
      "maxInputTokens": 8192, 
      "maxOutputTokens": 4096,
      "supportedLanguages": model.supportedLanguages.map { $0.identifier },
      "supportsStreaming": true,
      "supportsToolCalling": true,
      "version": "26.0",
    ]
    result(caps)
  }

  @available(iOS 26.0, *)
  private func ask(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let promptText = dict["prompt"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "prompt missing", details: nil))
      return
    }
    run(promptText: promptText, args: dict, postProcess: { $0 }, result: result)
  }

  @available(iOS 26.0, *)
  private func generateText(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let promptText = dict["prompt"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "prompt missing", details: nil))
      return
    }
    run(promptText: promptText, args: dict, postProcess: { $0 }, result: result)
  }

  @available(iOS 26.0, *)
  private func generateAlternatives(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let promptText = dict["prompt"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "prompt missing", details: nil))
      return
    }
    let count = dict["count"] as? Int ?? 3
    let altPrompt = """
      You are an expert copywriter.
      Generate exactly \(count) distinct alternatives for the following text.
      Do not add any extra commentary, numbering, or bullet points. Each alternative must be on a new line.

      Text: "\(promptText)"
      """
    run(
      promptText: altPrompt, args: dict,
      postProcess: { text in
        Array(text.split(separator: "\n").map { String($0).trimmed }.prefix(count))
      }, result: result)
  }

  @available(iOS 26.0, *)
  private func summarizeText(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let text = dict["text"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "text missing", details: nil))
      return
    }
    let style = dict["style"] as? String ?? "concise"
    let styleInstruction = styleInstruction(for: style)
    let summaryPrompt = """
      You are a text summarization expert. Your task is to summarize the following text.
      The desired style is \(styleInstruction).
      Provide only the summary without any introduction or conclusion.

      Text to summarize:
      ---
      \(text)
      ---
      """
    run(promptText: summaryPrompt, args: dict, postProcess: { $0 }, result: result)
  }

  @available(iOS 26.0, *)
  private func extractInformation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let text = dict["text"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "text missing", details: nil))
      return
    }
    let fields = (dict["fields"] as? [String])?.joined(separator: ", ") ?? "all key information"
    let promptText = """
      Analyze the following text and extract the specified information.
      Return the result as a single, valid JSON object with the following keys: [\(fields)].
      If a field is not found in the text, its value in the JSON should be null.

      Text:
      ---
      \(text)
      ---

      JSON Output:
      """
    run(
      promptText: promptText, args: dict,
      postProcess: { content in
        // Attempt to clean up markdown code block
        let cleanedContent =
          content.trimmingCharacters(in: .whitespacesAndNewlines)
          .replacingOccurrences(of: "```json", with: "")
          .replacingOccurrences(of: "```", with: "")
          .trimmed
        if let data = cleanedContent.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data)
        {
          return obj
        }
        return ["error": "Failed to parse JSON", "raw_content": content]
      }, result: result)
  }

  @available(iOS 26.0, *)
  private func classifyText(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let text = dict["text"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "text missing", details: nil))
      return
    }
    let categories = (dict["categories"] as? [String]) ?? ["positive", "negative", "neutral"]
    let promptText = """
      You are a text classification model. Analyze the following text and classify it according to these categories: [\(categories.joined(separator: ", "))].
      Your response must be a single, valid JSON object where keys are the category names and values are confidence scores between 0.0 and 1.0.

      Text to classify:
      "\(text)"

      JSON Output:
      """
    run(
      promptText: promptText, args: dict,
      postProcess: { content in
        let cleanedContent =
          content.trimmingCharacters(in: .whitespacesAndNewlines)
          .replacingOccurrences(of: "```json", with: "")
          .replacingOccurrences(of: "```", with: "")
          .trimmed
        if let data = cleanedContent.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data)
        {
          return obj
        }
        let even = 1.0 / Double(categories.count)
        return Dictionary(uniqueKeysWithValues: categories.map { ($0, even) })
      }, result: result)
  }

  @available(iOS 26.0, *)
  private func generateSuggestions(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let context = dict["context"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "context missing", details: nil))
      return
    }
    let max = dict["maxSuggestions"] as? Int ?? 5
    let promptText = """
      Based on the following context, provide exactly \(max) relevant and helpful suggestions.
      Do not number them or add any extra text. Each suggestion should be on a new line.

      Context:
      "\(context)"
      """
    run(
      promptText: promptText, args: dict,
      postProcess: { text in
        Array(text.split(separator: "\n").map { String($0).trimmed }.prefix(max))
      }, result: result)
  }

  @available(iOS 26.0, *)
  private func getStructuredData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let promptText = dict["prompt"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "prompt missing", details: nil))
      return
    }
    let structuredPrompt = """
      Your task is to respond to the user's request by providing the information in a valid JSON format.
      Based on the user's request, determine the appropriate JSON structure.

      User Request: "\(promptText)"

      JSON Output:
      """
    run(
      promptText: structuredPrompt, args: dict,
      postProcess: { content in
        let cleanedContent =
          content.trimmingCharacters(in: .whitespacesAndNewlines)
          .replacingOccurrences(of: "```json", with: "")
          .replacingOccurrences(of: "```", with: "")
          .trimmed
        if let data = cleanedContent.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data)
        {
          return obj
        }
        return ["error": "Failed to parse JSON", "raw_content": content]
      }, result: result)
  }

  @available(iOS 26.0, *)
  private func getListOfString(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let dict = call.arguments as? [String: Any],
      let promptText = dict["prompt"] as? String
    else {
      complete(
        result,
        error: FlutterError(code: "INVALID_ARGUMENTS", message: "prompt missing", details: nil))
      return
    }
    let listPrompt = """
      Generate a list of items based on the following request.
      Each item must be on a new line. Do not include numbering, bullet points, or any other formatting.

      Request: \(promptText)
      """
    run(
      promptText: listPrompt, args: dict,
      postProcess: { content in
        content.split(separator: "\n").map { String($0).trimmed }
      }, result: result)
  }

  @available(iOS 26.0, *)
  private func run<T>(
    promptText: String,
    args: [String: Any],
    postProcess: ((String) -> T)? = nil,
    result: @escaping FlutterResult
  ) {
    Task {
      do {
        let session = await session(for: args["sessionId"] as? String)
        let prompt = Prompt(promptText)
        let opts = options(from: args) ?? GenerationOptions()
        let raw = try await session.respond(to: prompt, options: opts)
        let output: Any = postProcess?(raw.content) ?? raw.content
        complete(result, with: output)
      } catch { complete(result, error: error) }
    }
  }

  private func styleInstruction(for style: String) -> String {
    switch style {
    case "concise": return "concise"
    case "detailed": return "detailed"
    case "bullet": return "as a bulleted list"
    case "key_points": return "as key points"
    default: return "concise"
    }
  }
}

// Only define this extension if the FoundationModels framework is available
#if canImport(FoundationModels)
  @available(iOS 26.0, *)
  extension SystemLanguageModel.Availability.UnavailableReason {
    var flutterCode: String {
      switch self {
      case .appleIntelligenceNotEnabled: "APPLE_INTELLIGENCE_NOT_ENABLED"
      case .deviceNotEligible: "DEVICE_NOT_ELIGIBLE"
      case .modelNotReady: "MODEL_NOT_READY"
      @unknown default: "UNAVAILABLE"
      }
    }
    var flutterMessage: String {
      switch self {
      case .appleIntelligenceNotEnabled: "Apple Intelligence is not enabled on this device."
      case .deviceNotEligible: "This device is not eligible for Apple Intelligence."
      case .modelNotReady: "The language model is not yet ready. It may be downloading."
      @unknown default: "The language model is unavailable for an unknown reason."
      }
    }
  }
#endif

extension String {
  fileprivate var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
