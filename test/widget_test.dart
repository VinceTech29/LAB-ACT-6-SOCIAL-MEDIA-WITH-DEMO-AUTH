import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:social_media_pablo/demo_auth.dart';
import 'package:social_media_pablo/login_screen.dart';
import 'package:social_media_pablo/main.dart';
import 'package:social_media_pablo/main_screen.dart';
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

  testWidgets('Complete Integrated Application Flow (Tests 1-14)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Test 1: Open the application -> Login appears first.
    await tester.pumpWidget(const StudentApp());
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // Test 2: Submit empty login fields -> Validation messages appear.
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    expect(find.text('Please enter your username'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // Test 3: Enter incorrect credentials -> Login is rejected.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'wronguser',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrongpass',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    ScaffoldMessenger.of(tester.element(find.byType(LoginScreen)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    // Test 4 & 5: Enter admin / admin123 -> Dashboard opens and displays Welcome, admin!
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

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.text('Welcome, admin!'), findsOneWidget);

    // Checkpoint Step 7: Calculator 20 & 5 operations + Test 6 (10 + 5 = 15.0)
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Calculator'),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'First Number'),
      '20',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Second Number'),
      '5',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, '+'));
    await tester.pump();
    expect(find.text('25.0'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '−'));
    await tester.pump();
    expect(find.text('15.0'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '×'));
    await tester.pump();
    expect(find.text('100.0'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '÷'));
    await tester.pump();
    expect(find.text('4.0'), findsOneWidget);

    // Test 6: Calculate 10 + 5 -> Displays 15.0.
    await tester.enterText(
      find.widgetWithText(TextField, 'First Number'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Second Number'),
      '5',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, '+'));
    await tester.pump();
    expect(find.text('15.0'), findsOneWidget);

    // Test 7: Switch tabs and return to Calculator -> Inputs and result remain.
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Dashboard'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, admin!'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Calculator'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('15.0'), findsOneWidget);

    // Test 8: Create a social post -> Post displays the logged-in username.
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Social'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Caption'),
      'Hello from admin!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Image URL'),
      'https://picsum.photos/id/20/600/400',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    expect(find.text('Hello from admin!'), findsOneWidget);
    final adminPostCard = find.ancestor(
      of: find.text('Hello from admin!'),
      matching: find.byType(PostCard),
    );
    expect(
      find.descendant(of: adminPostCard, matching: find.text('admin')),
      findsOneWidget,
    );

    // Test 9: Like a post and add a comment -> Both interactions update correctly.
    await tester.tap(
      find.descendant(of: adminPostCard, matching: find.text('Like')),
    );
    await tester.pump();
    expect(
      find.descendant(of: adminPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    await tester.enterText(
      find.descendant(
        of: adminPostCard,
        matching: find.widgetWithText(TextField, 'Add a comment...'),
      ),
      'Great integrated app!',
    );
    await tester.tap(
      find.descendant(of: adminPostCard, matching: find.byIcon(Icons.send)),
    );
    await tester.pump();
    expect(find.text('Great integrated app!'), findsOneWidget);
    expect(
      find.descendant(of: adminPostCard, matching: find.text('1 Comments')),
      findsOneWidget,
    );

    // Test 10: Switch tabs and return to Social -> Posts, likes, and comments remain.
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Dashboard'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Social'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Hello from admin!'), findsOneWidget);
    expect(
      find.descendant(of: adminPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );
    expect(find.text('Great integrated app!'), findsOneWidget);

    // Test 11: Open Profile -> Student information and username appear.
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Profile'),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Student Profile'), findsOneWidget);
    expect(find.text('LOURDE VINCENT M. PABLO'), findsOneWidget);
    expect(find.text('Logged in as: admin'), findsOneWidget);
    expect(find.text('553470'), findsOneWidget);
    expect(find.text('BSIT — CCE106L (3447)'), findsOneWidget);
    expect(find.text('lourdevincentpablo26@gmail.com'), findsOneWidget);

    // Test 12: Tap Logout -> Login appears; Back does not reopen MainScreen.
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(DemoAuth.currentUsername, isNull);
    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigatorState.canPop(), isFalse);

    // Test 13: Register a valid account and log in -> Dashboard displays registered username.
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

    expect(find.byType(LoginScreen), findsOneWidget);
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

    expect(find.text('Welcome, MariaClara!'), findsOneWidget);

    // Also check Profile shows registered username
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Profile'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Logged in as: MariaClara'), findsOneWidget);

    // Test 14: Create a post using the registered account -> Post displays registered username.
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Social'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Caption'),
      'Post by MariaClara',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Image URL'),
      'https://picsum.photos/id/30/600/400',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    expect(find.text('Post by MariaClara'), findsOneWidget);
    final mariaPostCard = find.ancestor(
      of: find.text('Post by MariaClara'),
      matching: find.byType(PostCard),
    );
    expect(
      find.descendant(of: mariaPostCard, matching: find.text('MariaClara')),
      findsOneWidget,
    );
  });
}
