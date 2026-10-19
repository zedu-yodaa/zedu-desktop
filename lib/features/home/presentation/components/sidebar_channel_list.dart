import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The workspace's channels in the home sidebar. Tapping a row opens it.
///
/// Public channels come first. Private channels follow under their own
/// "Private" heading, each with a lock instead of "#".
class SidebarChannelList extends ConsumerWidget {
  const SidebarChannelList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelState = ref.watch(channelProvider);
    final orgId = ref.watch(
      workspaceProvider.select((s) => s.selectedWorkspace?.id),
    );
    // Right after a workspace switch, and when the new workspace's load
    // failed, the state still holds the previous workspace's channels. Show
    // only channels of the selected workspace, and none after a failed load.
    // A channel without an organisation id is kept, since we can't tell.
    final channels =
        (channelState.hasError
                ? const <Channel>[]
                : channelState.value ?? const <Channel>[])
            .where(
              (c) =>
                  !c.archived &&
                  (c.organisationId.isEmpty || c.organisationId == orgId),
            )
            .toList();
    final publicChannels = channels.where((c) => !c.isPrivate);
    final privateChannels = channels.where((c) => c.isPrivate).toList();

    void open(Channel channel) =>
        ref.read(activeChatProvider.notifier).selectChannel(channel.name);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          for (final channel in publicChannels)
            _SidebarChannelItem(
              label: channel.name,
              onTap: () => open(channel),
            ),
          if (privateChannels.isNotEmpty) ...[
            const _SidebarSectionHeading(label: 'Private'),
            for (final channel in privateChannels)
              _SidebarChannelItem(
                label: channel.name,
                isPrivate: true,
                onTap: () => open(channel),
              ),
          ],
        ],
      ),
    );
  }
}

/// A section heading inside the channel list, styled like "Channels".
class _SidebarSectionHeading extends StatelessWidget {
  final String label;

  const _SidebarSectionHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(Icons.arrow_drop_down, color: colors.onPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarChannelItem extends StatelessWidget {
  final String label;
  final bool isPrivate;
  final VoidCallback onTap;

  const _SidebarChannelItem({
    required this.label,
    this.isPrivate = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            if (isPrivate)
              Icon(
                Icons.lock,
                key: const ValueKey('private-channel-lock'),
                size: 16,
                color: colors.onPrimary.withValues(alpha: 0.54),
              )
            else
              Text(
                '#',
                style: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.54),
                  fontSize: 18,
                ),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onPrimary, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
