# majid_flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running on iOS

Launch the app with `flutter run` (or build with `flutter build ios`) from the
project directory.

`permission_handler_apple` works out which permissions to compile in by reading
`ios/Runner/Info.plist` from its SwiftPM manifest. The manifest runs sandboxed
with none of Xcode's build settings, so it finds the app by walking up from the
working directory. `flutter run` and `flutter build ios` start in the project
directory and it resolves; a build started from **Xcode.app** runs with `/` as
its working directory, finds nothing, and silently compiles **every** permission
out — Privacy & Permissions then shows every row as unreadable and no permission
prompt ever appears.

To run from Xcode.app anyway, point the manifest at the plist once per machine:

```sh
launchctl setenv PERMISSION_HANDLER_INFO_PLIST "$(pwd)/ios/Runner/Info.plist"
rm -rf ~/Library/Developer/Xcode/DerivedData
```

The permissions imoscan declares are Camera, Photos, Location (While Using),
Notifications and Bluetooth. The microphone is deliberately **not** declared.
