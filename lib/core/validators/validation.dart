import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

String validatedText(
  dynamic value,
  int maxLength,
  String message,
) {
  final text = (value ?? '').toString().trim();

  if (text.isEmpty || text.length > maxLength) {
    throw Exception(message);
  }

  return text;
}

num validatedNumber(
  dynamic value,
  num minimum,
  num maximum,
  String message,
) {
  if (value is! num || !value.isFinite || value < minimum || value > maximum) {
    throw Exception(message);
  }

  return value;
}

String validatedJobId(dynamic value) {
  final id = value?.toString();

  if (id == null || id.isEmpty || id.length > 150 || id.contains('/')) {
    throw Exception('Invalid service request ID.');
  }

  return id;
}

String savedContactPhone(Map<String, dynamic>? contact) {
  final phone = contact?['phone'];

  if (phone is! String || !RegExp(r'^\+947[0-9]{8}$').hasMatch(phone)) {
    throw Exception(
      'Please add your mobile number through My account first.',
    );
  }

  return phone;
}

Blob? validatedImage(dynamic value) {
  if (value == null || value == '') {
    return null;
  }

  if (value is! Uint8List || value.isEmpty || value.length > 300 * 1024) {
    throw Exception(
      'Select a valid image smaller than 300 KB.',
    );
  }

  return Blob(value);
}

double coarseCoordinate(num value) {
  return (value * 100 + 0.5).floor() / 100.0;
}
