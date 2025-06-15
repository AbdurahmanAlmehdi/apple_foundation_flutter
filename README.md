# Apple Foundation Flutter

A Flutter plugin that provides access to Apple's Foundation Models framework for iOS 18.0 and above. This plugin enables Flutter apps to integrate with Apple's on-device language models for text generation and structured data generation.

## Features

- **Streaming Text Generation**: Get real-time streaming responses from Apple's Foundation Models
- **Structured Data Generation**: Generate structured data using guided generation
- **On-Device Processing**: All processing happens locally on the device using Apple's Foundation Models framework
- **Privacy-First**: No data is sent to external servers

## Requirements

- iOS 26.0 or higher
- Xcode 16.0 or higher
- Swift 5.0 or higher
- Flutter 3.0 or higher

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


## Usage

### Import the Plugin

```dart
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';
```

### Initialize the Plugin

```dart
final appleFoundationFlutter = AppleFoundationFlutter();
```

### Streaming Text Generation

Generate text with real-time streaming responses:

```dart
// Stream responses from the Foundation Model
appleFoundationFlutter
    .ask('Tell me a story about a brave knight.')
    .listen((chunk) {
      print('Received chunk: $chunk');
      // Update your UI with each chunk as it arrives
    });
```

### Structured Data Generation

Generate structured data using guided generation:

```dart
try {
  final structuredData = await appleFoundationFlutter
      .getStructuredData('Generate a user profile for John Doe, age 30');

  print('Name: ${structuredData['name']}');
  print('Age: ${structuredData['value']}');
  print('Description: ${structuredData['description']}');
} catch (error) {
  print('Error generating structured data: $error');
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

class FoundationModelsDemo extends StatefulWidget {
  @override
  _FoundationModelsDemoState createState() => _FoundationModelsDemoState();
}

class _FoundationModelsDemoState extends State<FoundationModelsDemo> {
  final _plugin = AppleFoundationFlutter();
  String _response = '';
  Map<String, dynamic>? _structuredData;

  void _getStreamingResponse() {
    _plugin.ask('Tell me a story about a brave knight.').listen((data) {
      setState(() {
        _response += data;
      });
    });
  }

  void _getStructuredData() async {
    try {
      final data = await _plugin.getStructuredData(
          'Generate a user profile for a person named John Doe who is 30 years old.');
      setState(() {
        _structuredData = data;
      });
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Foundation Models Demo')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _getStreamingResponse,
              child: Text('Get Streaming Response'),
            ),
            SizedBox(height: 16),
            Text('Response: $_response'),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _getStructuredData,
              child: Text('Get Structured Data'),
            ),
            SizedBox(height: 16),
            if (_structuredData != null)
              Text('Structured Data: $_structuredData'),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### Methods

#### `ask(String prompt)`

Streams responses from Apple's Foundation Model.

- **Parameters**:
  - `prompt`: The input text prompt
- **Returns**: `Stream<String>` - Stream of generated text chunks
- **Throws**: `PlatformException` if the operation fails

#### `getStructuredData(String prompt)`

Generates structured data from Apple's Foundation Model using guided generation.

- **Parameters**:
  - `prompt`: The input text prompt
- **Returns**: `Future<Map<String, dynamic>>` - Structured data as a Map
- **Throws**: `PlatformException` if the operation fails

#### `getPlatformVersion()`

Gets the current platform version.

- **Returns**: `Future<String?>` - Platform version string

## Error Handling

The plugin provides comprehensive error handling. It's recommended to wrap API calls in a `try-catch` block to handle potential `PlatformException` errors.

```dart
try {
  final result = await appleFoundationFlutter.getStructuredData('Generate data');
  // Handle success
} on PlatformException catch (e) {
  switch (e.code) {
    // General errors
    case 'INVALID_ARGUMENTS':
      print('Invalid arguments provided');
      break;
    case 'GENERATION_ERROR':
      print('Error during generation: ${e.message}');
      break;
    case 'ENCODING_ERROR':
      print('Error encoding response');
      break;
    
    // Availability errors
    case 'UNSUPPORTED_OS':
      print('This feature is only available on iOS.');
      break;
    case 'DEVICE_NOT_ELIGIBLE':
      print('This device does not support Apple Intelligence.');
      break;
    case 'APPLE_INTELLIGENCE_NOT_ENABLED':
      print('Apple Intelligence is not enabled in settings.');
      break;
    case 'MODEL_NOT_READY':
      print('The language model is still downloading.');
      break;
    case 'UNAVAILABLE':
      print('The model is unavailable for an unknown reason.');
      break;

    default:
      print('Unknown error: ${e.message}');
  }
}
```

## Limitations

- Only available on iOS 18.0 and above
- Requires devices with Apple Silicon or A-series processors
- Model availability depends on device capabilities and iOS configuration
- Processing happens on-device, so performance varies by device

## Privacy

This plugin processes all data locally on the device using Apple's Foundation Models framework. No data is transmitted to external servers, ensuring complete privacy and compliance with data protection regulations.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for more details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [Flutter Plugin Development](https://docs.flutter.dev/packages-and-plugins/developing-packages)
