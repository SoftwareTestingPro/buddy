import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Notification Service:
/// Manages real-time phone alerts, in-app top drop-down banners, and persistent notification inbox
class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  GlobalKey<NavigatorState>? navigatorKey;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Load cached notifications from SharedPreferences
  Future<void> init(String? currentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('cached_notifications_${currentUserId ?? "guest"}') ?? [];

    _notifications.clear();
    for (final item in cached) {
      try {
        _notifications.add(AppNotification.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('[NotificationService] Error restoring cached notification: $e');
      }
    }

    if (currentUserId != null && currentUserId.isNotEmpty) {
      await syncRemoteNotifications(currentUserId);
    }
    notifyListeners();
  }

  /// Sync notifications from Supabase
  Future<void> syncRemoteNotifications(String userId) async {
    try {
      final remoteList = await SupabaseService.instance.fetchNotifications(userId);
      bool hasNew = false;

      for (final row in remoteList) {
        final notif = AppNotification.fromJson(row);
        final existingIdx = _notifications.indexWhere((n) => n.id == notif.id);
        if (existingIdx < 0) {
          _notifications.insert(0, notif);
          hasNew = true;
        }
      }

      if (hasNew) {
        await _saveLocally(userId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationService] Error syncing remote notifications: $e');
    }
  }

  /// Send a notification to a specific recipient (User1 or User2).
  /// Persists to Supabase, local cache, and displays an on-device Heads-Up Banner.
  Future<void> send({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String bookingId,
    required String title,
    required String message,
    required String type,
    String? currentUserId,
  }) async {
    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}',
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      bookingId: bookingId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
    );

    // 1. Persist to Supabase so the recipient receives it across devices
    await SupabaseService.instance.sendNotification(notif.toJson());

    // 2. If the current logged in user on this phone is the recipient, save to local inbox & trigger phone banner
    if (currentUserId != null && currentUserId == recipientId) {
      _notifications.insert(0, notif);
      await _saveLocally(currentUserId);
      notifyListeners();
      showHeadsUpNotification(notif);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        SupabaseService.instance.markNotificationAsRead(_notifications[i].id);
      }
    }
    await _saveLocally(userId);
    notifyListeners();
  }

  /// Mark individual notification as read
  Future<void> markAsRead(String notifId, String userId) async {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      await _saveLocally(userId);
      await SupabaseService.instance.markNotificationAsRead(notifId);
      notifyListeners();
    }
  }

  /// Display a native-like Heads-Up Notification Banner at the top of the phone screen
  void showHeadsUpNotification(AppNotification notification) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _HeadsUpBannerWidget(
            notification: notification,
            onDismiss: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss banner after 4.5 seconds
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  Future<void> _saveLocally(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('cached_notifications_$userId', jsonList);
  }
}

class _HeadsUpBannerWidget extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;

  const _HeadsUpBannerWidget({
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_HeadsUpBannerWidget> createState() => _HeadsUpBannerWidgetState();
}

class _HeadsUpBannerWidgetState extends State<_HeadsUpBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.event_available_rounded;
      case 'booking_accepted':
        return Icons.check_circle_rounded;
      case 'booking_declined':
        return Icons.cancel_rounded;
      case 'booking_cancelled':
        return Icons.event_busy_rounded;
      case 'meetup_started':
        return Icons.timer_rounded;
      case 'meetup_ended':
        return Icons.task_alt_rounded;
      case 'dispute':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'booking_accepted':
      case 'meetup_ended':
        return AppTheme.success;
      case 'booking_declined':
      case 'booking_cancelled':
      case 'dispute':
        return Colors.red.shade600;
      case 'meetup_started':
        return const Color(0xFF4F46E5);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(widget.notification.type);

    return SlideTransition(
      position: _offsetAnimation,
      child: Dismissible(
        key: Key(widget.notification.id),
        direction: DismissDirection.up,
        onDismissed: (_) => widget.onDismiss(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: typeColor.withOpacity(0.35), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getTypeIcon(widget.notification.type), color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          'Just now',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.notification.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onDismiss,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
