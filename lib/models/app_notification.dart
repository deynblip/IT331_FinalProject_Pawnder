enum NotificationType {
  rescueResponse, // someone is responding to the user's stray report
  applicationForOwner, // an application for the user's pet needs a decision
  applicationForwarded, // the user's application was forwarded to the owner
  applicationApproved,
  applicationRejected,
  postRemoved, // an adoption post was removed by an admin
  postApproved,
  rescuerApproved, // the admin approved the Verified Rescuer application
  rescuerRejected, // the admin rejected the Verified Rescuer application
  rescuerFlagged, // (admin) a Verified Rescuer has a high cancel rate
  applicationSubmitted, // (admin) a new adoption application needs screening
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;

  /// The report / application the notification is about (may be null).
  final String? targetId;

  /// If set, only this user sees the notification (null = everyone).
  final String? userEmail;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.targetId,
    this.userEmail,
  });

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      read: read ?? this.read,
      targetId: targetId,
      userEmail: userEmail,
    );
  }

  /// Example: "5 min ago", "Yesterday", "November 12, 2026"
  String get timeText {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }
}