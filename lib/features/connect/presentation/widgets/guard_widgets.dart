import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shahkar_connect/core/l10n/s.dart';
import 'package:shahkar_connect/features/connect/guard/connection_guard.dart';
import 'package:shahkar_connect/features/connect/quality/connection_quality.dart';

const _teal = Color(0xFF17B290);
const _amber = Color(0xFFF5A623);
const _red = Color(0xFFE4556E);
const _panel = Color(0xFF0E1114);
const _stroke = Color(0xFF23272C);

Color gradeColor(ConnectionGrade grade) {
  switch (grade) {
    case ConnectionGrade.excellent:
    case ConnectionGrade.good:
      return _teal;
    case ConnectionGrade.fair:
      return _amber;
    case ConnectionGrade.poor:
    case ConnectionGrade.dead:
      return _red;
  }
}

String gradeLabel(ConnectionGrade grade, S s) {
  switch (grade) {
    case ConnectionGrade.excellent:
      return s.qualityExcellent;
    case ConnectionGrade.good:
      return s.qualityGood;
    case ConnectionGrade.fair:
      return s.qualityFair;
    case ConnectionGrade.poor:
      return s.qualityPoor;
    case ConnectionGrade.dead:
      return s.qualityDead;
  }
}

/// Live link quality: grade, jitter and packet loss.
class QualityChip extends StatelessWidget {
  const QualityChip({
    super.key,
    required this.quality,
    required this.scanning,
    required this.s,
  });

  final ConnectionQuality quality;
  final bool scanning;
  final S s;

  @override
  Widget build(BuildContext context) {
    if (!quality.hasData && !scanning) return const SizedBox.shrink();
    final color = scanning ? _amber : gradeColor(quality.grade);
    final text = scanning
        ? s.scanningServers
        : '${gradeLabel(quality.grade, s)} · ${quality.latencyMs}ms · '
            '${s.jitter} ${quality.jitterMs}ms · ${s.packetLoss} ${quality.lossPct}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 7.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prompt shown when a measurably faster server is available.
class SwitchSuggestionCard extends StatelessWidget {
  const SwitchSuggestionCard({
    super.key,
    required this.suggestion,
    required this.s,
    required this.onAccept,
    required this.onDismiss,
  });

  final SwitchSuggestion suggestion;
  final S s;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _teal.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: _teal, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  s.betterServer,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (suggestion.server.flagAsset != null)
                ClipOval(
                  child: Image.asset(
                    suggestion.server.flagAsset!,
                    width: 18.r,
                    height: 18.r,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            s.betterServerBody(suggestion.server.name, suggestion.gain),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: s.switchNow,
                  filled: true,
                  onTap: onAccept,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _CardButton(label: s.notNow, onTap: onDismiss),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown while the firewall lockdown is holding traffic.
class LockdownCard extends StatelessWidget {
  const LockdownCard({
    super.key,
    required this.s,
    required this.onUnlock,
    this.reconnecting = false,
  });

  final S s;
  final VoidCallback onUnlock;
  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 10.w, 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0F14),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: _red, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.internetLocked,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  reconnecting ? s.reconnecting : s.internetLockedBody,
                  style: TextStyle(color: Colors.white60, fontSize: 10.5.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          _CardButton(label: s.unlockInternet, onTap: onUnlock, dense: true),
        ],
      ),
    );
  }
}

/// Short-lived confirmation such as "switched to Germany".
class GuardNoticeBar extends StatelessWidget {
  const GuardNoticeBar({
    super.key,
    required this.text,
    required this.onClose,
    this.tone = _teal,
  });

  final String text;
  final VoidCallback onClose;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 6.w, 8.h),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: tone, size: 15.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 11.sp),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            iconSize: 15.sp,
            color: Colors.white38,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: 4.w),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _teal : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12.w : 10.w,
            vertical: dense ? 7.h : 9.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: filled ? null : Border.all(color: _stroke),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : Colors.white70,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
