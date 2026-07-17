import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// Soft size hint only — no hard rejection for PNG/JPEG menu images.
const menuScanMaxBytes = 25 * 1024 * 1024;

bool isMenuImageFile(XFile file) {
  final mime = (file.mimeType ?? '').toLowerCase();
  if (mime.startsWith('image/')) return true;
  final name = file.name.toLowerCase();
  return name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.webp') ||
      name.endsWith('.gif') ||
      name.endsWith('.bmp') ||
      name.endsWith('.heic') ||
      name.endsWith('.heif');
}

/// Always returns a plain base64 [String] (no `data:` prefix) for the API.
Future<({String b64, String mime})> encodeMenuFile(XFile file) async {
  final bytes = await file.readAsBytes();
  final mime = _resolveMime(file, bytes);
  final b64 = _toBase64String(bytes);
  return (b64: b64, mime: mime);
}

String _toBase64String(Uint8List bytes) {
  // Guarantee a Dart [String] — never list/bytes for the API payload.
  var encoded = base64Encode(bytes);
  // Strip accidental data-URL wrappers if present.
  final comma = encoded.indexOf(',');
  if (encoded.startsWith('data:') && comma != -1) {
    encoded = encoded.substring(comma + 1);
  }
  return encoded.trim();
}

String _resolveMime(XFile file, Uint8List bytes) {
  final mime = (file.mimeType ?? '').trim().toLowerCase();
  if (mime.startsWith('image/') || mime.startsWith('application/') || mime.startsWith('text/')) {
    return mime;
  }

  // Magic-byte sniff for common images when extension/mime is missing.
  if (bytes.length >= 8) {
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'image/webp';
    }
  }

  final lower = file.name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  return 'image/jpeg';
}

Future<int> fileSizeBytes(XFile file) async {
  if (file.path.isNotEmpty) {
    try {
      return await File(file.path).length();
    } catch (_) {
      // Fall through to reading bytes.
    }
  }
  return (await file.readAsBytes()).length;
}
