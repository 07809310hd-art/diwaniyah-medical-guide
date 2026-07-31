// This is a basic Flutter widget test for the Diwaniyah medical guide app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diwaniyah_medical_guide/main.dart';

void main() {
  testWidgets('Shows a loading indicator then the onboarding screen for a new user', (WidgetTester tester) async {
    // The app reads SharedPreferences on startup to check for a registered
    // user; mock it so the test doesn't depend on a real platform channel.
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiwaniyahMedicalApp());

    // While the app checks for a previously registered user, it shows a spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Once the check completes, a new user lands on the onboarding screen.
    // (Not using pumpAndSettle here: the app has continuously repeating
    // animations, which would make it time out waiting to settle.)
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('مرحباً بك في دليل أطباء الديوانية'), findsOneWidget);
  });
}
