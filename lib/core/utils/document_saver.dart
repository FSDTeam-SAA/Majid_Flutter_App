import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Where a generated document ended up on the device.
class SavedDocument {
  final File file;

  /// Human readable location for the confirmation message.
  final String locationLabel;

  const SavedDocument({required this.file, required this.locationLabel});
}

/// Copies a generated PDF out of the app's temporary directory into a folder
/// that survives a restart and can be reached from a file browser.
///
/// The PDFs the invoice flow builds live in the temp directory, which the OS is
/// free to purge, so nothing was really "saved on the phone" before.
abstract final class DocumentSaver {
  /// Saves [source] under [fileName] and returns where it landed.
  static Future<SavedDocument> save(File source, {String? fileName}) async {
    final name = fileName ?? source.uri.pathSegments.last;
    final directory = await _targetDirectory();
    final target = File('${directory.path}/$name');

    await target.parent.create(recursive: true);
    await source.copy(target.path);

    return SavedDocument(file: target, locationLabel: _labelFor(directory));
  }

  /// Android gives an app scoped Downloads folder that needs no permission;
  /// iOS has no Downloads at all, so documents go to the app's Documents
  /// folder, which the Files app can show.
  static Future<Directory> _targetDirectory() async {
    if (!Platform.isIOS) {
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) return downloads;
      } catch (_) {
        // Falls through to the documents directory below.
      }
    }
    return getApplicationDocumentsDirectory();
  }

  static String _labelFor(Directory directory) {
    if (directory.path.toLowerCase().contains('download')) {
      return 'Downloads';
    }
    return Platform.isIOS ? 'Files app' : 'app documents';
  }
}
