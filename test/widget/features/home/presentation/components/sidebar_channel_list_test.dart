import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

Channel _channel(
  String name, {
  bool archived = false,
  bool isPrivate = false,
  String org = 'org-1',
}) => Channel(
  id: 'channel-$name',
  name: name,
  description: '',
  organisationId: org,
  isPrivate: isPrivate,
  ownerId: 'user-1',
  archived: archived,
);

class FakeChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [
    _channel('general'),
    _channel('random'),
    _channel('old', archived: true),
  ];
}

class MixedChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [
    _channel('general'),
    _channel('leads', isPrivate: true),
    _channel('random'),
    _channel('secret-old', isPrivate: true, archived: true),
  ];
}

class PrivateOnlyChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [_channel('leads', isPrivate: true)];
}

/// Holds one selected workspace, and can switch to another.
class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Workspace A', avatar: ''),
  );

  void switchTo(String id) {
    state = WorkspaceState(
      selectedWorkspace: Workspace(id: id, name: 'Workspace $id', avatar: ''),
    );
  }
}

/// Lists workspace A's channels until [switched] is set. After that, the next
/// build loads workspace B's channels, or fails when [failB] is set. It does
/// not watch the workspace, so it stays stale until it is invalidated, like
/// the real provider in the moment after a switch.
class SwitchingChannelNotifier extends ChannelNotifier {
  static bool switched = false;
  static bool failB = false;

  @override
  Future<List<Channel>> build() async {
    if (!switched) return [_channel('a-only')];
    if (failB) throw const ApiFailure(message: 'Could not load channels');
    return [_channel('b-only', org: 'org-2')];
  }
}

void main() {
  group('SidebarChannelList', () {
    late ProviderContainer container;

    Future<void> pumpList(
      WidgetTester tester, {
      required ChannelNotifier Function() channels,
    }) async {
      container = ProviderContainer(
        overrides: [
          channelProvider.overrideWith(channels),
          workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestMaterialApp(
            const Scaffold(body: SidebarChannelList()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    FakeWorkspaceNotifier workspace() =>
        container.read(workspaceProvider.notifier) as FakeWorkspaceNotifier;

    testWidgets('lists the active channels and hides archived ones', (
      tester,
    ) async {
      await pumpList(tester, channels: FakeChannelNotifier.new);

      expect(find.text('general'), findsOneWidget);
      expect(find.text('random'), findsOneWidget);
      expect(find.text('old'), findsNothing);
    });

    group('after a workspace switch', () {
      setUp(() {
        SwitchingChannelNotifier.switched = false;
        SwitchingChannelNotifier.failB = false;
      });

      testWidgets('hides the old channels until the new ones arrive', (
        tester,
      ) async {
        await pumpList(tester, channels: SwitchingChannelNotifier.new);
        expect(find.text('a-only'), findsOneWidget);

        // The workspace changes before the channel list has reloaded.
        workspace().switchTo('org-2');
        await tester.pumpAndSettle();
        expect(find.text('a-only'), findsNothing);

        SwitchingChannelNotifier.switched = true;
        container.invalidate(channelProvider);
        await tester.pumpAndSettle();

        expect(find.text('b-only'), findsOneWidget);
        expect(find.text('a-only'), findsNothing);
      });

      testWidgets('shows no channels when the new load fails', (tester) async {
        await pumpList(tester, channels: SwitchingChannelNotifier.new);
        expect(find.text('a-only'), findsOneWidget);

        workspace().switchTo('org-2');
        SwitchingChannelNotifier.switched = true;
        SwitchingChannelNotifier.failB = true;
        container.invalidate(channelProvider);
        await tester.pumpAndSettle();

        expect(find.text('a-only'), findsNothing);
        expect(find.text('b-only'), findsNothing);
      });
    });

    group('Private section', () {
      const lock = ValueKey('private-channel-lock');

      testWidgets('lists private channels under "Private" with a lock', (
        tester,
      ) async {
        await pumpList(tester, channels: MixedChannelNotifier.new);

        expect(find.text('Private'), findsOneWidget);
        expect(find.byKey(lock), findsOneWidget);
        expect(find.text('#'), findsNWidgets(2));

        final randomTop = tester.getTopLeft(find.text('random')).dy;
        final headingTop = tester.getTopLeft(find.text('Private')).dy;
        final leadsTop = tester.getTopLeft(find.text('leads')).dy;
        expect(randomTop, lessThan(headingTop));
        expect(headingTop, lessThan(leadsTop));
      });

      testWidgets('hides archived private channels', (tester) async {
        await pumpList(tester, channels: MixedChannelNotifier.new);

        expect(find.text('secret-old'), findsNothing);
      });

      testWidgets('shows no "Private" heading without private channels', (
        tester,
      ) async {
        await pumpList(tester, channels: FakeChannelNotifier.new);

        expect(find.text('Private'), findsNothing);
        expect(find.byKey(lock), findsNothing);
      });

      testWidgets('works with only private channels', (tester) async {
        await pumpList(tester, channels: PrivateOnlyChannelNotifier.new);

        expect(find.text('Private'), findsOneWidget);
        expect(find.text('leads'), findsOneWidget);
        expect(find.text('#'), findsNothing);
      });

      testWidgets('tapping a private channel opens it', (tester) async {
        await pumpList(tester, channels: MixedChannelNotifier.new);

        await tester.tap(find.text('leads'));
        await tester.pump();

        expect(
          container.read(activeChatProvider),
          const ActiveChatState(type: ActiveChatType.channel, id: 'leads'),
        );
      });
    });

    testWidgets('tapping a channel opens it', (tester) async {
      await pumpList(tester, channels: FakeChannelNotifier.new);
      expect(container.read(activeChatProvider).id, 'general');

      await tester.tap(find.text('random'));
      await tester.pump();

      expect(
        container.read(activeChatProvider),
        const ActiveChatState(type: ActiveChatType.channel, id: 'random'),
      );
    });
  });
}
