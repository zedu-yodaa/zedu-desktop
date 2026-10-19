import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The card at the top of your own space (the DM with yourself), in place of
/// the "just between you and @name" card other DMs show.
class OwnSpaceIntro extends StatelessWidget {
  const OwnSpaceIntro({
    super.key,
    required this.conversation,
    required this.onEditProfile,
  });

  final DmConversation conversation;

  /// Opens the Edit profile dialog. Both buttons use it, because that dialog
  /// is also where you change your profile photo.
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = conversation.displayName;
    final avatarUrl = conversation.effectiveAvatarUrl;
    final avatar = avatarUrl != null && avatarUrl.isNotEmpty
        ? NetworkImage(avatarUrl)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 76, 40, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 39,
            backgroundColor: colors.primary,
            backgroundImage: avatar,
            child: avatar != null
                ? null
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              text: name,
              children: [
                TextSpan(
                  text: ' (you)',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Only you can see this.',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text:
                      ' Save resources from class, keep track of your tasks, '
                      'or draft a message here before you post it to a '
                      'channel.',
                ),
              ],
            ),
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IntroButton(label: 'Edit profile', onPressed: onEditProfile),
              _IntroButton(
                label: 'Add a profile photo',
                onPressed: onEditProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroButton extends StatelessWidget {
  const _IntroButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
