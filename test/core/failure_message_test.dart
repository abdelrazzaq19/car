import 'dart:async';
import 'dart:io';

import 'package:car_rental_app/core/error/failure_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('failureMessage', () {
    test('maps an offline Firestore error to offline wording', () {
      final message = failureMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(message, contains('offline'));
    });

    test('maps permission-denied to sign-in wording', () {
      final message = failureMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      expect(message, contains('permission'));
    });

    test('maps a socket failure to offline wording', () {
      expect(
        failureMessage(const SocketException('failed host lookup')),
        contains('offline'),
      );
    });

    test('maps a timeout to retry wording', () {
      expect(
        failureMessage(TimeoutException('too slow')),
        contains('took too long'),
      );
    });

    test('never leaks the raw exception text', () {
      final message = failureMessage(
        Exception('[cloud_firestore/internal] secret stack detail'),
      );

      expect(message, isNot(contains('cloud_firestore')));
      expect(message, isNot(contains('secret')));
    });
  });
}
