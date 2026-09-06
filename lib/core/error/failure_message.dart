import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Turns an exception into something worth showing a user.
///
/// The UI previously rendered `e.toString()`, which surfaced text like
/// "[cloud_firestore/permission-denied] ..." on screen.
///
/// [action] names what was being attempted, so the generic fallback reads
/// naturally: "loading cars", "confirming your booking".
String failureMessage(Object error, {String action = 'loading cars'}) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' ||
      'network-request-failed' =>
        'You appear to be offline. Check your connection and try again.',
      'permission-denied' =>
        'You do not have permission to do that. Please sign in again.',
      'deadline-exceeded' => 'The request took too long. Please try again.',
      'not-found' => 'That is no longer available.',
      'resource-exhausted' => 'The service is busy. Please try again shortly.',
      _ => 'Something went wrong while $action. Please try again.',
    };
  }

  if (error is SocketException || error is HttpException) {
    return 'You appear to be offline. Check your connection and try again.';
  }

  if (error is TimeoutException) {
    return 'The request took too long. Please try again.';
  }

  return 'Something went wrong while $action. Please try again.';
}
