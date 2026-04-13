import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_baby_sara/data/services/notification_service.dart';

/// Debug-only test panel — SizedBox.shrink() in release builds.
/// Location: Account page → scroll to bottom.
///
/// How to test:
///  ⚡ "Şimdi Gönder"  → show() — fires instantly, most reliable
///  ⏱ "10 sn Sonra"  → alarmClock mode — close app to tray, wait 10 s
class NotificationTestPanel extends StatefulWidget {
  const NotificationTestPanel({super.key});

  @override
  State<NotificationTestPanel> createState() => _NotificationTestPanelState();
}

class _NotificationTestPanelState extends State<NotificationTestPanel> {
  List<PendingNotificationRequest> _pending = [];
  String _lastResult = '—';
  bool _loading = false;
  bool? _permGranted;
  bool? _initialized;
  String _timezone = '—';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final status = await NotificationService.instance.debugStatus();
    if (!mounted) return;
    setState(() {
      _initialized = status['initialized'] as bool;
      _permGranted = status['permission'] as bool;
      _timezone = status['timezone'] as String;
    });
    await _refreshPending();
  }

  Future<void> _refreshPending() async {
    final list = await NotificationService.instance.pendingList();
    if (!mounted) return;
    setState(() => _pending = list);
  }

  /// Runs [fn] and surfaces success OR the real exception message.
  Future<void> _run(String label, Future<void> Function() fn) async {
    setState(() {
      _loading = true;
      _lastResult = '$label çalışıyor…';
    });
    try {
      await fn();
      await _refreshStatus();
      if (!mounted) return;
      setState(() => _lastResult = '✅ $label başarılı');
    } catch (e) {
      // Exception is intentionally NOT swallowed — shown in result box.
      await _refreshStatus();
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
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8.h),
      color: const Color(0xFFFFF3CD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                const Text('🔔', style: TextStyle(fontSize: 17)),
                SizedBox(width: 6.w),
                Text(
                  'Notification Tests  [DEBUG ONLY]',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF856404),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loading ? null : _refreshStatus,
                  child: Icon(Icons.refresh,
                      size: 18.sp, color: const Color(0xFF856404)),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // ── Status Row ───────────────────────────────────────────────────
            _StatusRow(
              initialized: _initialized,
              permGranted: _permGranted,
              timezone: _timezone,
              pendingCount: _pending.length,
            ),
            const Divider(height: 14),

            // ── INSTANT buttons (⚡ show() — no scheduling) ──────────────────
            Text(
              '⚡ Anında Gönder  (app açıkken de çalışır)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 5.h,
              children: [
                _Btn(
                  label: '🌙 Sleep — şimdi',
                  disabled: _loading,
                  onTap: () => _run('Sleep (anında)', () async {
                    await NotificationService.instance.debugShowNow(
                      title: context.tr('notif_sleep_title'),
                      body: context.tr(
                        'notif_sleep_body',
                        namedArgs: {'name': 'Test'},
                      ),
                      id: 9001,
                    );
                  }),
                ),
                _Btn(
                  label: '🍼 Feed — şimdi',
                  disabled: _loading,
                  onTap: () => _run('Feed (anında)', () async {
                    await NotificationService.instance.debugShowNow(
                      title: context.tr('notif_feed_title'),
                      body: context.tr(
                        'notif_feed_body',
                        namedArgs: {'name': 'Test'},
                      ),
                      id: 9002,
                    );
                  }),
                ),
                _Btn(
                  label: '🌟 Milestone — şimdi',
                  disabled: _loading,
                  onTap: () => _run('Milestone (anında)', () async {
                    await NotificationService.instance.debugShowNow(
                      title: context.tr(
                        'notif_milestone_title',
                        namedArgs: {'name': 'Test', 'month': '3'},
                      ),
                      body: context.tr(
                        'notif_milestone_body',
                        namedArgs: {'name': 'Test', 'month': '3'},
                      ),
                      id: 9003,
                    );
                  }),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // ── TIMED buttons (⏱ alarmClock — app arka planda) ──────────────
            Text(
              '⏱ 10 sn Sonra  (arka plana al → bekle)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 5.h,
              children: [
                _Btn(
                  label: '🌙 Sleep — 10 sn',
                  disabled: _loading,
                  onTap: () => _run('Sleep (10 sn)', () async {
                    await NotificationService.instance.debugFireIn(
                      afterSeconds: 10,
                      title: context.tr('notif_sleep_title'),
                      body: context.tr(
                        'notif_sleep_body',
                        namedArgs: {'name': 'Test'},
                      ),
                      id: 9011,
                    );
                  }),
                ),
                _Btn(
                  label: '🍼 Feed — 10 sn',
                  disabled: _loading,
                  onTap: () => _run('Feed (10 sn)', () async {
                    await NotificationService.instance.debugFireIn(
                      afterSeconds: 10,
                      title: context.tr('notif_feed_title'),
                      body: context.tr(
                        'notif_feed_body',
                        namedArgs: {'name': 'Test'},
                      ),
                      id: 9012,
                    );
                  }),
                ),
                _Btn(
                  label: '🌟 Milestone — 10 sn',
                  disabled: _loading,
                  onTap: () => _run('Milestone (10 sn)', () async {
                    await NotificationService.instance.debugFireIn(
                      afterSeconds: 10,
                      title: context.tr(
                        'notif_milestone_title',
                        namedArgs: {'name': 'Test', 'month': '3'},
                      ),
                      body: context.tr(
                        'notif_milestone_body',
                        namedArgs: {'name': 'Test', 'month': '3'},
                      ),
                      id: 9013,
                    );
                  }),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // ── Utility buttons ──────────────────────────────────────────────
            Wrap(
              spacing: 6.w,
              runSpacing: 5.h,
              children: [
                // Only show "İzin İste" when permission is missing
                if (_permGranted == false)
                  _Btn(
                    label: '🔓 İzin İste',
                    color: Colors.orange.shade100,
                    disabled: _loading,
                    onTap: () => _run('İzin İste', () async {
                      final granted =
                          await NotificationService.instance.requestPermission();
                      if (!granted) {
                        throw Exception(
                          'İzin verilmedi. Cihaz Ayarları → Uygulamalar → '
                          'Sara Baby → Bildirimler → Aç',
                        );
                      }
                    }),
                  ),
                _Btn(
                  label: '🗓 Pending listesi',
                  disabled: _loading,
                  onTap: _refreshStatus,
                ),
                _Btn(
                  label: '🗑 Tümünü iptal',
                  color: Colors.red.shade100,
                  disabled: _loading,
                  onTap: () => _run('Tümünü iptal', () async {
                    await NotificationService.instance.cancelAll();
                  }),
                ),
              ],
            ),

            // ── Result box ───────────────────────────────────────────────────
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _lastResult,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontFamily: 'monospace',
                  color: _lastResult.startsWith('❌')
                      ? Colors.red.shade700
                      : Colors.black87,
                ),
              ),
            ),

            // ── Pending list ─────────────────────────────────────────────────
            if (_pending.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Scheduled: ${_pending.length} bildirim',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF856404),
                ),
              ),
              SizedBox(height: 3.h),
              ..._pending.take(6).map(
                    (n) => Text(
                      'ID ${n.id}  ${n.title ?? "(no title)"}',
                      style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.black54,
                          fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              if (_pending.length > 6)
                Text(
                  '  … +${_pending.length - 6} tane daha',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Status Row ───────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.initialized,
    required this.permGranted,
    required this.timezone,
    required this.pendingCount,
  });

  final bool? initialized;
  final bool? permGranted;
  final String timezone;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _StatusChip(
          label: initialized == null
              ? 'Init: ?'
              : initialized!
                  ? 'Init ✓'
                  : 'Init ✗',
          ok: initialized,
        ),
        _StatusChip(
          label: permGranted == null
              ? 'İzin: ?'
              : permGranted!
                  ? 'İzin ✓'
                  : 'İZİN YOK ✗',
          ok: permGranted,
        ),
        _StatusChip(label: '🕐 $timezone', ok: true),
        _StatusChip(label: '📋 $pendingCount scheduled', ok: true),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.ok});

  final String label;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final color = ok == null
        ? Colors.grey.shade300
        : ok!
            ? Colors.green.shade100
            : Colors.red.shade200;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: Colors.black87,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ─── Button ───────────────────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.onTap,
    this.color,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.shade300
              : (color ?? Colors.white.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: disabled ? Colors.grey.shade400 : const Color(0xFFFFC107),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: disabled ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }
}
