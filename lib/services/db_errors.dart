import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===============================
// DATABASE ERROR MESSAGES
// ===============================

const String kNoInternetMessage =
    'No internet connection. Please check your connection and try again.';

const String kSomethingWrongMessage = 'Something went wrong. Please try again.';

String friendlyDbError(Object error, {String fallback = kSomethingWrongMessage}) {
  debugPrint('Database error: $error');

  if (isNetworkError(error)) return kNoInternetMessage;

  if (error is PostgrestException) {
    if (error.code == 'P0001' && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error.code == '23514' || error.code == '22001') {
      return 'Some details are too long or missing. Please check and try again.';
    }
    if (error.code == 'PGRST301' || error.message.contains('JWT')) {
      return 'Your session has expired. Please log in again.';
    }
    return fallback;
  }

  if (error is StorageException) {
    final String msg = error.message.toLowerCase();
    if (msg.contains('size') || error.statusCode == '413') {
      return 'The photo is too large. Please choose a photo under 5 MB.';
    }
    if (msg.contains('mime') || msg.contains('type')) {
      return 'This photo type is not supported. Please use a JPG or PNG photo.';
    }
    return 'Could not upload the photo. Please try again.';
  }

  if (error is AuthException) {
    return 'Your session has expired. Please log in again.';
  }

  return fallback;
}

bool isNetworkError(Object error) {
  final String s = error.toString();
  return s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('ClientException') ||
      s.contains('Connection refused') ||
      s.contains('Connection reset') ||
      s.contains('XMLHttpRequest') ||
      s.contains('TimeoutException');
}