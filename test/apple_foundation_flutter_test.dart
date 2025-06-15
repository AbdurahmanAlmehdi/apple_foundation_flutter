// import 'package:flutter_test/flutter_test.dart';
// import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';
// import 'package:apple_foundation_flutter/apple_foundation_flutter_platform_interface.dart';
// import 'package:apple_foundation_flutter/apple_foundation_flutter_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockAppleFoundationFlutterPlatform
//     with MockPlatformInterfaceMixin
//     implements AppleFoundationFlutterPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
  
//   @override
//   Stream<String> ask(String prompt) {
//     return Stream.value('Give me a list of 10 random words');
//   }
  
//   @override
//   Future<Map<String, dynamic>> getStructuredData(String prompt) {
//     return Future.value({'test': 'test'});
//   }
// }

// void main() {
//   final AppleFoundationFlutterPlatform initialPlatform = AppleFoundationFlutterPlatform.instance;

//   test('$MethodChannelAppleFoundationFlutter is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelAppleFoundationFlutter>());
//   });

//   test('getPlatformVersion', () async {
//     AppleFoundationFlutter appleFoundationFlutterPlugin = AppleFoundationFlutter();
//     MockAppleFoundationFlutterPlatform fakePlatform = MockAppleFoundationFlutterPlatform();
//     AppleFoundationFlutterPlatform.instance = fakePlatform;

//     expect(await appleFoundationFlutterPlugin.getPlatformVersion(), '42');
//   });
// }
