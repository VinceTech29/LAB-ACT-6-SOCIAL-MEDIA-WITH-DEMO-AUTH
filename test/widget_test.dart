import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:social_media_pablo/demo_auth.dart';
import 'package:social_media_pablo/main.dart';
import 'package:social_media_pablo/social_media/create_post_sheet.dart';
import 'package:social_media_pablo/social_media/post_card.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUp(() {
    HttpOverrides.global = TestHttpOverrides();
    DemoAuth.registeredUsername = null;
    DemoAuth.registeredPassword = null;
    DemoAuth.currentUsername = null;
  });

  Future<void> loginAsAdmin(WidgetTester tester) async {
    await tester.pumpWidget(const StudentApp());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'admin123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();
  }

  testWidgets('Full Social Media Feed & Navigation Test Suite',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Log in using default admin account
    await loginAsAdmin(tester);
    expect(find.text('Welcome, Student!'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // 2. Open Social Media tab
    await tester.tap(find.text('Social Media').last);
    await tester.pumpAndSettle();

    // Check sample posts
    expect(find.widgetWithText(AppBar, 'Social Media'), findsOneWidget);
    expect(find.text('JohnDoe'), findsOneWidget);
    expect(find.text('Enjoying the sunny weather!'), findsOneWidget);
    expect(find.text('JaneSmith'), findsOneWidget);
    expect(find.text('Just finished a great book!'), findsOneWidget);

    // 3. Test empty fields validation
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Create Post'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pump();
    expect(
      find.text('Complete both fields before submitting!'),
      findsOneWidget,
    );
    ScaffoldMessenger.of(tester.element(find.byType(CreatePostSheet))).clearSnackBars();
    await tester.pumpAndSettle();

    // 4. Test invalid URL validation
    await tester.enterText(
      find.widgetWithText(TextField, 'Caption'),
      'My first Flutter social media post!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Image URL or File Path'),
      'invalid-url',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pump();
    expect(
      find.text('Enter a valid HTTP or HTTPS image URL or file path.'),
      findsOneWidget,
    );
    ScaffoldMessenger.of(tester.element(find.byType(CreatePostSheet))).clearSnackBars();
    await tester.pumpAndSettle();

    // 5. Submit valid post
    await tester.enterText(
      find.widgetWithText(TextField, 'Image URL or File Path'),
      'https://picsum.photos/id/20/600/400',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    // Confirm post appears at top with admin username
    expect(find.text('My first Flutter social media post!'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);

    // Test tapping image / badge to open in Windows File Explorer
    expect(find.text('Open in Explorer'), findsWidgets);
    final initialFirstCard = find.byType(PostCard).first;
    await tester.tap(
      find.descendant(of: initialFirstCard, matching: find.text('Open in Explorer')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pumpAndSettle();

    // 6. Tap Like twice (toggle)
    final firstCard = find.byType(PostCard).first;
    final likeButton = find.descendant(
      of: firstCard,
      matching: find.text('Like'),
    );
    await tester.tap(likeButton);
    await tester.pump();
    expect(
      find.descendant(of: firstCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: firstCard, matching: find.text('Liked')),
    );
    await tester.pump();
    expect(
      find.descendant(of: firstCard, matching: find.text('Like')),
      findsOneWidget,
    );

    // 7. Add nonempty comment
    final commentField = find.descendant(
      of: firstCard,
      matching: find.widgetWithText(TextField, 'Add a comment...'),
    );
    await tester.enterText(commentField, 'Awesome first post!');
    final sendButton = find.descendant(
      of: firstCard,
      matching: find.byIcon(Icons.send),
    );
    await tester.tap(sendButton);
    await tester.pump();

    expect(find.text('Awesome first post!'), findsOneWidget);
    expect(find.text('1 Comments'), findsOneWidget);

    // 8. Submit blank comment
    await tester.enterText(commentField, '   ');
    await tester.tap(sendButton);
    await tester.pump();
    expect(find.text('1 Comments'), findsOneWidget);

    // 9. Like sample post & user post, then create another post -> original keeps liked state
    final firstPostCard = find.ancestor(
      of: find.text('My first Flutter social media post!'),
      matching: find.byType(PostCard),
    );
    await tester.tap(
      find.descendant(of: firstPostCard, matching: find.text('Like')),
    );
    await tester.pump();
    expect(
      find.descendant(of: firstPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    final johnDoeCard = find.ancestor(
      of: find.text('JohnDoe'),
      matching: find.byType(PostCard),
    );
    await tester.tap(
      find.descendant(of: johnDoeCard, matching: find.text('Like')),
    );
    await tester.pump();
    expect(
      find.descendant(of: johnDoeCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    // Create another post
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Caption'),
      'Second post',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Image URL or File Path'),
      'https://picsum.photos/id/24/600/400',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    // Verify original posts kept their liked state and new post is unliked
    expect(find.text('Second post'), findsOneWidget);
    expect(
      find.descendant(of: firstPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: johnDoeCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    // 10. Switch to Home and return -> feed preserved
    await tester.tap(find.text('Home').last);
    await tester.pump();
    expect(find.text('Welcome, Student!'), findsOneWidget);

    await tester.tap(find.text('Social Media').last);
    await tester.pump();
    expect(find.text('Second post'), findsOneWidget);
    expect(find.text('My first Flutter social media post!'), findsOneWidget);

    // 11. Log out, register, and log in with a new account
    await tester.tap(find.text('Profile').last);
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Logout'));
    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);

    // Register new user
    await tester.tap(find.widgetWithText(OutlinedButton, 'Register'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'MariaClara',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pumpAndSettle();

    // Log in with new user
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'MariaClara',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Student!'), findsOneWidget);

    // Open Social Media and create post as new user
    await tester.tap(find.text('Social Media').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Caption'),
      'Post by MariaClara',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Image URL or File Path'),
      'https://picsum.photos/id/30/600/400',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    expect(find.text('Post by MariaClara'), findsOneWidget);
    expect(find.text('MariaClara'), findsOneWidget);
  });
}
