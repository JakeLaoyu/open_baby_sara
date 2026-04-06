import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_baby_sara/data/services/notification_service.dart';

/// Debug-only panel — compiled away completely in release builds.
/// Shows up in Account page under a "🔔 Notification Tests" section.
class NotificationTestPanel extends StatefulWidget {
  const NotificationTestPanel({super.key});

  @override
  State<NotificationTestPanel> createState() => _NotificationTestPanelState();
}

class _NotificationTestPanelState extends State<NotificationTestPanel> {
  List<PendingNotificationRequest> _pending = [];
  String _lastResult = '—';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshPending();
  }

  Future<void> _refreshPending() async {
    final list = await NotificationService.instance.pendingList();
    if (!mounted) return;
    setState(() => _pending = list);
  }

  Future<void> _run(String label, Future<void> Function() fn) async {
    setState(() {
      _loading = true;
      _lastResult = '$label…';
    });
    try {
      await fn();
      await _refreshPending();
      if (!mounted) return;
      setState(() => _lastResult = '✅ $label done');
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastResult = '❌ $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: const Color(0xFFFFF3CD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔔', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8.w),
                Text(
                  'Notification Tests  [DEBUG]',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF856404),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Release build\'ta bu panel görünmez.',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
            const Divider(height: 16),

            // ── Test Buttons ──────────────────────────────────────────────────
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _TestButton(
                  label: '🌙 Sleep (10 sn)',
                  onTap: _loading
                      ? null
                      : () => _run('Sleep reminder', () async {
                            await NotificationService.instance
                                .scheduleSleepReminder(
                              babyName: 'Test',
                              title: '🌙 Uyku kaydı zamanı',
                              body: 'Test bebeği biraz uyanık kaldı.',
                              debugAfterSeconds: 10,
                            );
                          }),
                ),
                _TestButton(
                  label: '🍼 Feed (10 sn)',
                  onTap: _loading
                      ? null
                      : () => _run('Feed reminder', () async {
                            await NotificationService.instance
                                .scheduleFeedReminder(
                              title: '🍼 Beslenme vakti mi?',
                              body: 'Test bebeğini besleme zamanı.',
                              debugAfterSeconds: 10,
                            );
                          }),
                ),
                _TestButton(
                  label: '🌟 Milestone (10 sn)',
                  onTap: _loading
                      ? null
                      : () => _run('Milestone', () async {
                            await NotificationService.instance.debugFireIn(
                              afterSeconds: 10,
                              title: '🌟 Bebek 3 aylık oldu!',
                              body: 'Bu ayki gelişim basamaklarına bak.',
                              payload: 'milestone_3',
                            );
                          }),
                ),
                _TestButton(
                  label: '🗓 Pending listesi',
                  onTap: _loading ? null : _refreshPending,
                ),
                _TestButton(
                  label: '🗑 Tümünü iptal',
                  color: Colors.red.shade100,
                  onTap: _loading
                      ? null
                      : () => _run('Cancel all', () async {
                            await NotificationService.instance.cancelAll();
                          }),
                ),
              ],
            ),

            // ── Last Result ───────────────────────────────────────────────────
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _lastResult,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
              ),
            ),

            // ── Pending Notifications List ────────────────────────────────────
            if (_pending.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                'Bekleyen bildirimler: ${_pending.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF856404),
                ),
              ),
              SizedBox(height: 4.h),
              ..._pending.take(8).map(
                    (n) => Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        'ID ${n.id}: ${n.title}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.black54,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              if (_pending.length > 8)
                Text(
                  '... ve ${_pending.length - 8} tane daha',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
            ] else
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  'Bekleyen bildirim yok.',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({
    required this.label,
    required this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade300
              : (color ?? Colors.white.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFFFC107)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: onTap == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }
}
