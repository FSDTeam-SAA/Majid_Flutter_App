import 'package:flutter/material.dart';
import 'colors.dart';

enum StatusTone {
  safe, // Emerald / Green
  warning, // Amber / Yellow
  danger, // Red / Rose
  neutral, // Slate / Gray
}

class StatusStyle {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final StatusTone tone;

  const StatusStyle({
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.tone,
  });
}

class StatusHelper {
  static const Set<String> _statusFieldKeywords = {
    'ACTIVATION STATUS',
    'DEVICE ACTIVATION',
    'REGISTRATION STATUS',
    'FIND MY IPHONE',
    'FIND MY',
    'ICLOUD LOCK',
    'ICLOUD STATUS',
    'MI ACTIVATION LOCK',
    'SIM LOCK STATUS',
    'SIM LOCK',
    'SIMPOLICY UNLOCK STATUS',
    'UNLOCK STATUS',
    'NETWORK LOCK',
    'MDM LOCK',
    'MDM STATUS',
    'MDM',
    'KNOX GUARD',
    'KNOX STATUS',
    'KNOX LOCK',
    'KNOX',
    'BTU',
    'BTU STATUS',
    'BLACKLIST STATUS',
    'BLACKLIST',
    'REPORTED STOLEN',
    'WARRANTY STATUS',
    'LIMITED WARRANTY',
    'COVERAGE STATUS',
    'APPLECARE COVERED',
    'APPLECARE ELIGIBLE',
    'REPLACED DEVICE',
    'REPLACEMENT DEVICE',
    'REFURBISHED DEVICE',
    'DEMO UNIT',
    'IS DEMO',
    'IS VALID',
    'LOANER DEVICE',
    'LOST MODE',
    'TEMP COVERAGE',
    'OPEN REPAIR',
    'VALID PURCHASE DATE',
    'AT&T STATUS',
    'DEVICE STATUS',
    'CARRIER FINANCING',
  };

  /// Returns true if the field label represents a status check
  static bool isStatusField(String label) {
    final cleanLabel = label.trim().toUpperCase();
    if (_statusFieldKeywords.contains(cleanLabel)) return true;
    for (final keyword in _statusFieldKeywords) {
      if (cleanLabel.contains(keyword)) return true;
    }
    return false;
  }

  /// Evaluates status value and returns corresponding tone matching the website
  static StatusTone getTone(String value, {String? fieldLabel}) {
    final val = value.trim().toLowerCase();
    final field = (fieldLabel ?? '').trim().toUpperCase();

    // 1. Context-specific checks based on fieldLabel

    // iCloud Lock / Find My iPhone / MI Lock / MDM Lock / Knox Guard / Lost Mode
    final isLockField =
        field.contains('ICLOUD') ||
        field.contains('FIND MY') ||
        field.contains('MDM') ||
        field.contains('KNOX') ||
        field.contains('LOST MODE') ||
        field.contains('LOCK');

    if (isLockField) {
      if (val == 'off' ||
          val == 'clean' ||
          val == 'disabled' ||
          val == 'unlocked' ||
          val == 'normal' ||
          val == 'no' ||
          val == 'false') {
        return StatusTone.safe;
      }
      if (val == 'on' ||
          val == 'locked' ||
          val == 'enabled' ||
          val == 'active' ||
          val == 'yes' ||
          val == 'true' ||
          val == 'lost' ||
          val == 'stolen' ||
          val == 'enrolled') {
        return StatusTone.danger;
      }
    }

    // Blacklist / Stolen fields
    final isBlacklistField =
        field.contains('BLACKLIST') ||
        field.contains('STOLEN') ||
        field.contains('BLOCKED');

    if (isBlacklistField) {
      if (val == 'clean' ||
          val == 'not blacklisted' ||
          val == 'not reported stolen' ||
          val == 'no' ||
          val == 'false' ||
          val == 'unlocked' ||
          val == 'passed') {
        return StatusTone.safe;
      }
      if (val == 'blacklisted' ||
          val == 'reported stolen' ||
          val == 'stolen' ||
          val == 'lost' ||
          val == 'blocked' ||
          val == 'barred' ||
          val == 'yes' ||
          val == 'true') {
        return StatusTone.danger;
      }
    }

    // Replaced / Refurbished / Demo / Repair
    final isDeviceFlagField =
        field.contains('REPLACED') ||
        field.contains('REPLACEMENT') ||
        field.contains('REFURBISHED') ||
        field.contains('DEMO') ||
        field.contains('LOANER') ||
        field.contains('OPEN REPAIR');

    if (isDeviceFlagField) {
      if (val == 'no' || val == 'false' || val == 'clean') {
        return StatusTone.safe;
      }
      if (val == 'yes' || val == 'true') {
        return StatusTone.danger;
      }
    }

    // Activation Status
    final isActivationField =
        field.contains('ACTIVATION') || field.contains('REGISTRATION');

    if (isActivationField) {
      if (val == 'activated' ||
          val == 'active' ||
          val == 'yes' ||
          val == 'clean' ||
          val == 'passed' ||
          val == 'registered') {
        return StatusTone.safe;
      }
      if (val == 'not activated' ||
          val == 'not active' ||
          val == 'inactive' ||
          val == 'not registered' ||
          val == 'no') {
        return StatusTone.warning;
      }
    }

    // BTU / Carrier check
    if (field.contains('BTU')) {
      if (val == 'clean' || val == 'off' || val == 'passed' || val == 'no') {
        return StatusTone.safe;
      }
      if (val == 'flagged' ||
          val == 'locked' ||
          val == 'failed' ||
          val == 'yes') {
        return StatusTone.danger;
      }
      if (val == 'unknown' || val == 'pending') {
        return StatusTone.warning;
      }
    }

    // 2. Generic status value mapping (matching website SingleResultView.tsx and SearchHistory.tsx)
    if (val == 'clean' ||
        val == 'active' ||
        val == 'activated' ||
        val == 'off' ||
        val == 'unlocked' ||
        val == 'unlock' ||
        val == 'no' ||
        val == 'passed' ||
        val == 'in warranty' ||
        val == 'completed' ||
        val == 'ok' ||
        val == 'valid' ||
        val == 'normal') {
      return StatusTone.safe;
    }

    if (val == 'not active' ||
        val == 'not activated' ||
        val == 'inactive' ||
        val == 'unknown' ||
        val == 'warning' ||
        val == 'pending' ||
        val == 'in progress' ||
        val == 'financed' ||
        val == 'payment plan active' ||
        val == 'limited warranty' ||
        val == 'under review') {
      return StatusTone.warning;
    }

    if (val == 'blacklisted' ||
        val == 'reported stolen' ||
        val == 'stolen' ||
        val == 'lost' ||
        val == 'lost mode' ||
        val == 'blocked' ||
        val == 'locked' ||
        val == 'on' ||
        val == 'failed' ||
        val == 'flagged' ||
        val == 'barred' ||
        val == 'bad' ||
        val == 'issue') {
      return StatusTone.danger;
    }

    if (val.contains('stolen') ||
        val.contains('blacklist') ||
        val.contains('blocked') ||
        val.contains('barred')) {
      return StatusTone.danger;
    }

    if (val.contains('not active') ||
        val.contains('not activated') ||
        val.contains('inactive') ||
        val.contains('pending')) {
      return StatusTone.warning;
    }

    if (val.contains('clean') ||
        val.contains('unlocked') ||
        val == 'pass' ||
        val.contains('passed')) {
      return StatusTone.safe;
    }

    return StatusTone.neutral;
  }

  /// Builds the complete StatusStyle (text, bg, border) matching the website's Tailwind theme
  static StatusStyle getStyle(String value, {String? fieldLabel}) {
    final tone = getTone(value, fieldLabel: fieldLabel);
    final isDark = AppColors.isDark;

    switch (tone) {
      case StatusTone.safe: // Emerald / Green
        return StatusStyle(
          textColor: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
          backgroundColor:
              isDark ? const Color(0x3310B981) : const Color(0xFFD1FAE5),
          borderColor:
              isDark ? const Color(0x4D10B981) : const Color(0xFFA7F3D0),
          tone: tone,
        );

      case StatusTone.warning: // Amber / Yellow
        return StatusStyle(
          textColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
          backgroundColor:
              isDark ? const Color(0x33F59E0B) : const Color(0xFFFEF3C7),
          borderColor:
              isDark ? const Color(0x4DF59E0B) : const Color(0xFFFDE68A),
          tone: tone,
        );

      case StatusTone.danger: // Red / Rose
        return StatusStyle(
          textColor: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
          backgroundColor:
              isDark ? const Color(0x33EF4444) : const Color(0xFFFEE2E2),
          borderColor:
              isDark ? const Color(0x4DEF4444) : const Color(0xFFFECACA),
          tone: tone,
        );

      case StatusTone.neutral: // Slate / Neutral
        return StatusStyle(
          textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderColor:
              isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          tone: tone,
        );
    }
  }
}
