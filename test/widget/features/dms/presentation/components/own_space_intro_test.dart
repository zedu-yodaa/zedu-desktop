import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

const _intro =
    'Only you can see this. Save resources from class, keep track of your '
    'tasks, or draft a message here before you post it to a channel.';

Future<int Function()> _pumpIntro(WidgetTester tester) async {
  var taps = 0;
  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: OwnSpaceIntro(
          conversation: DmConversation(
            channelId: 'channel-me',
            username: 'Jenie',
            participantId: 'me',
            previewMessage: '',
            unreadCount: 0,
          ),
          onEditProfile: () => taps++,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return () => taps;
}

void main() {
  group('OwnSpaceIntro', () {
    testWidgets('shows your name with "(you)" and the intro text', (
      tester,
    ) async {
      await _pumpIntro(tester);

      expect(find.text('Jenie (you)'), findsOneWidget);
      expect(find.text(_intro), findsOneWidget);
      expect(find.textContaining('Check out their profile'), findsNothing);
      expect(find.text('View Profile'), findsNothing);
    });

    testWidgets('makes "Only you can see this." bold', (tester) async {
      await _pumpIntro(tester);

      final text = tester.widget<Text>(find.text(_intro));
      final span = text.textSpan! as TextSpan;
      final first = span.children!.first as TextSpan;

      expect(first.text, 'Only you can see this.');
      expect(first.style!.fontWeight, FontWeight.w600);
    });

    testWidgets('both buttons open Edit profile', (tester) async {
      final taps = await _pumpIntro(tester);

      await tester.tap(find.text('Edit profile'));
      await tester.tap(find.text('Add a profile photo'));
      await tester.pump();

      expect(taps(), 2);
    });
  });
}
