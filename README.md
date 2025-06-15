# Apple Foundation Flutter

A Flutter plugin that provides access to Apple's on-device Foundation Models framework, available on iOS 18.0 and above. This plugin allows you to integrate Apple Intelligence features directly into your Flutter applications, offering powerful, private, and efficient AI capabilities.

## Features

- **On-Device & Private**: All processing happens locally, ensuring user data remains private.
- **Text Generation**: Create rich, context-aware text content.
- **Streaming Support**: Stream text and structured JSON responses in real-time for a dynamic UX.
- **Structured Data**: Generate structured data (e.g., JSON) from natural language prompts.
- **Session Management**: Maintain conversation history and context with sessions.
- **Advanced Control**: Fine-tune model output with parameters like temperature, token limits, and more.
- **Helper Functions**: Includes specialized methods for summarization, classification, alternative generation, and information extraction.
- **Availability Checks**: Gracefully check if Apple Intelligence is available on the user's device.

## Requirements

- **Platform**: iOS 26.0+
- **IDE**: Xcode 16.0+
- **Language**: Swift 5.10+
- **Flutter**: 3.0+

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  apple_foundation_flutter: ^0.0.1
```

Then run:

```bash
flutter pub get
```

Finally, run `flutter pub get`.

## Usage

### 1. Initialize the Plugin

```dart
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

final _plugin = AppleFoundationFlutter();
```

### 2. Check for Availability

Before using any model features, always check if they are available on the device.

```dart
final bool isAvailable = await _plugin.isAvailable();
if (!isAvailable) {
  // Handle cases where Apple Intelligence is not available
  final status = await _plugin.getAvailabilityStatus();
  print('Apple Intelligence is not available: ${status['reason']}');
  return;
}
```

### 3. Generate Text (Streaming)

For dynamic and responsive UI, stream text generation.

```dart
String streamedResponse = '';
final textStream = _plugin.generateTextStream(
  'Tell me a short story about a brave knight.',
);

await for (final chunk in textStream) {
  setState(() {
    streamedResponse += chunk;
  });
}
```

### 4. Generate Structured Data (Streaming)

You can also stream structured data, which is useful for receiving a complete JSON object once it's fully generated.

```dart
String rawJson = '';
final jsonStream = _plugin.getStructuredDataStream(
  'Create a user profile for Jane Doe, a 32-year-old astronaut.',
);

await for (final chunk in jsonStream) {
  rawJson += chunk;
}
// Once the stream is complete, parse the JSON
final data = json.decode(rawJson);
print(data); // { "name": "Jane Doe", "age": 32, "occupation": "astronaut" }
```

### 5. Using Sessions for Context

Sessions allow the model to remember previous parts of a conversation.

```dart
// Start a new session with system instructions
final sessionId = await _plugin.openSession(
  'You are a helpful and friendly assistant.',
);

// Use the session ID in subsequent calls
final response = await _plugin.generateText(
  'What was the first thing I asked you?',
  sessionId: sessionId,
);

// Remember to close the session when done
await _plugin.closeSession(sessionId);

```

## API Reference

### Core Methods

- **`Future<bool> isAvailable()`**: Checks if Apple Intelligence is supported and enabled.
- **`Future<Map<String, dynamic>> getAvailabilityStatus()`**: Gets a detailed status, including a reason if unavailable.
- **`Future<Map<String, dynamic>> getModelCapabilities()`**: Returns a map of the current model's capabilities.
- **`Future<String?> getPlatformVersion()`**: Gets the underlying iOS version.

### Session Management

- **`Future<String> openSession(String instructions)`**: Creates a new session with system-level instructions and returns a unique session ID.
- **`Future<void> closeSession(String sessionId)`**: Closes and cleans up a session.

### Generation Methods (Single Response)

These methods return a complete response after generation is finished.

- **`Future<String?> ask(String prompt, {String? sessionId})`**: A simple method for a single question-and-answer interaction.
- **`Future<String?> generateText(String prompt, {String? sessionId, int? maxTokens, double? temperature, double? topP})`**: Generates text with advanced options.
- **`Future<Map<String, dynamic>> getStructuredData(String prompt, {String? sessionId})`**: Generates a JSON object from a prompt.
- **`Future<List<String>> getListOfString(String prompt, {String? sessionId})`**: Generates a list of strings, where each item is on a new line.
- **`Future<List<String>> generateAlternatives(String prompt, {String? sessionId, int count})`**: Generates a specified number of variations for a given text.
- **`Future<String?> summarizeText(String text, {String? sessionId, SummarizationStyle style})`**: Summarizes a piece of text in a specific style.
- **`Future<Map<String, dynamic>> extractInformation(String text, {String? sessionId, List<String>? fields})`**: Extracts specific fields from text into a JSON object.
- **`Future<Map<String, double>> classifyText(String text, {String? sessionId, List<String>? categories})`**: Classifies text against a list of categories and returns confidence scores.
- **`Future<List<String>> generateSuggestions(String context, {String? sessionId, int maxSuggestions})`**: Provides contextual suggestions.

### Generation Methods (Streaming)

- **`Stream<String> generateTextStream(String prompt, {String? sessionId, ...})`**: Streams generated text as a series of chunks.
- **`Stream<String> getStructuredDataStream(String prompt, {String? sessionId})`**: Streams a complete JSON object as a raw string. The stream will emit the full string in one or more chunks.

## Error Handling

The plugin uses `AppleFoundationException` for errors. It's best to wrap API calls in a `try-catch` block.

```dart
try {
  final result = await _plugin.generateText('Hello!');
} on AppleFoundationException catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  // e.g., 'UNSUPPORTED_OS_VERSION', 'MODEL_NOT_READY', etc.
  switch (e.code) {
    case 'UNSUPPORTED_OS_VERSION':
      // Handle OS not supported
      break;
    case 'MODEL_NOT_READY':
      // Inform user the model is downloading
      break;
    // ... handle other specific error codes
  }
}
```

### Common Error Codes

- **`UNSUPPORTED_OS_VERSION`**: The iOS version is below 18.0.
- **`DEVICE_NOT_ELIGIBLE`**: The device hardware does not support Apple Intelligence.
- **`APPLE_INTELLIGENCE_NOT_ENABLED`**: The user has not enabled Apple Intelligence in Settings.
- **`MODEL_NOT_READY`**: The language model is still downloading or is otherwise not ready.
- **`TIMEOUT_ERROR`**: The request to the native side timed out.
- **`GENERATION_ERROR`**: An error occurred within the native model during generation.
- **`INVALID_ARGUMENTS`**: One of the arguments passed to the method was invalid (e.g., empty prompt).

## Privacy

This plugin processes all data locally on the device using Apple's Foundation Models framework. **No data is transmitted to external servers**, ensuring complete privacy and compliance with data protection regulations.

## Contributing

We welcome contributions! Please see our Contributing Guide for more details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [Flutter Plugin Development](https://docs.flutter.dev/packages-and-plugins/developing-packages)
