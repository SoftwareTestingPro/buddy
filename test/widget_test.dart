import 'package:flutter_test/flutter_test.dart';
import 'package:buddy/main.dart';

void main() {
  testWidgets('Buddy App login gate smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BuddyApp());
    // Verification that Welcome/Buddy or Google Sign-In is displayed as the first page
    expect(find.text('Welcome to Buddy'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
