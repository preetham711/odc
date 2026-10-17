/// Reminder preferences stored in Hive settings box.
class ReminderSettings {
  final bool enabled;
  final int intervalMinutes; // 5,10,15,20,30,45,60
  final bool vibration;
  final bool repeatUntilReturn;
  final int maxDurationMinutes; // 0=unlimited,30,60,120
  final int quietStart; // hour 0-23, e.g. 22
  final int quietEnd;   // hour 0-23, e.g. 8
  final bool quietHoursEnabled;

  const ReminderSettings({
    this.enabled = true,
    this.intervalMinutes = 10,
    this.vibration = true,
    this.repeatUntilReturn = true,
    this.maxDurationMinutes = 0,
    this.quietStart = 22,
    this.quietEnd = 8,
    this.quietHoursEnabled = false,
  });

  static const _kEnabled = 'rem_enabled';
  static const _kInterval = 'rem_interval';
  static const _kVibration = 'rem_vibration';
  static const _kRepeat = 'rem_repeat';
  static const _kMaxDur = 'rem_max_dur';
  static const _kQuietStart = 'rem_quiet_start';
  static const _kQuietEnd = 'rem_quiet_end';
  static const _kQuietEnabled = 'rem_quiet_enabled';

  static ReminderSettings fromBox(dynamic box) {
    return ReminderSettings(
      enabled: box.get(_kEnabled, defaultValue: true) as bool,
      intervalMinutes: box.get(_kInterval, defaultValue: 10) as int,
      vibration: box.get(_kVibration, defaultValue: true) as bool,
      repeatUntilReturn: box.get(_kRepeat, defaultValue: true) as bool,
      maxDurationMinutes: box.get(_kMaxDur, defaultValue: 0) as int,
      quietStart: box.get(_kQuietStart, defaultValue: 22) as int,
      quietEnd: box.get(_kQuietEnd, defaultValue: 8) as int,
      quietHoursEnabled: box.get(_kQuietEnabled, defaultValue: false) as bool,
    );
  }

  Future<void> saveToBox(dynamic box) async {
    await box.put(_kEnabled, enabled);
    await box.put(_kInterval, intervalMinutes);
    await box.put(_kVibration, vibration);
    await box.put(_kRepeat, repeatUntilReturn);
    await box.put(_kMaxDur, maxDurationMinutes);
    await box.put(_kQuietStart, quietStart);
    await box.put(_kQuietEnd, quietEnd);
    await box.put(_kQuietEnabled, quietHoursEnabled);
  }

  ReminderSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
    bool? vibration,
    bool? repeatUntilReturn,
    int? maxDurationMinutes,
    int? quietStart,
    int? quietEnd,
    bool? quietHoursEnabled,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      vibration: vibration ?? this.vibration,
      repeatUntilReturn: repeatUntilReturn ?? this.repeatUntilReturn,
      maxDurationMinutes: maxDurationMinutes ?? this.maxDurationMinutes,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }
}
