import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/alarm_sound_service.dart';
import '../../services/permission_service.dart';
import '../../providers/mood_theme_provider.dart';

class AlarmSettingsScreen extends ConsumerStatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  ConsumerState<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends ConsumerState<AlarmSettingsScreen> {
  final AlarmSoundService _alarmService = AlarmSoundService();
  
  bool _checkInAlarmEnabled = false;
  bool _checkOutAlarmEnabled = false;
  bool _breakAlarmEnabled = false;
  
  TimeOfDay _checkInTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _breakTime = const TimeOfDay(hour: 12, minute: 30);
  
  String _selectedSound = 'Default Alarm';
  List<String> _availableSounds = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _alarmService.initialize();
    await _loadSettings();
    final sounds = await _alarmService.getSystemAlarmSounds();
    setState(() {
      _availableSounds = sounds;
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _checkInAlarmEnabled = prefs.getBool('check_in_alarm') ?? false;
      _checkOutAlarmEnabled = prefs.getBool('check_out_alarm') ?? false;
      _breakAlarmEnabled = prefs.getBool('break_alarm') ?? false;
      
      _checkInTime = TimeOfDay(
        hour: prefs.getInt('check_in_hour') ?? 9,
        minute: prefs.getInt('check_in_minute') ?? 0,
      );
      _checkOutTime = TimeOfDay(
        hour: prefs.getInt('check_out_hour') ?? 18,
        minute: prefs.getInt('check_out_minute') ?? 0,
      );
      _breakTime = TimeOfDay(
        hour: prefs.getInt('break_hour') ?? 12,
        minute: prefs.getInt('break_minute') ?? 30,
      );
      
      _selectedSound = prefs.getString('alarm_sound') ?? 'Default Alarm';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('check_in_alarm', _checkInAlarmEnabled);
    await prefs.setBool('check_out_alarm', _checkOutAlarmEnabled);
    await prefs.setBool('break_alarm', _breakAlarmEnabled);
    
    await prefs.setInt('check_in_hour', _checkInTime.hour);
    await prefs.setInt('check_in_minute', _checkInTime.minute);
    await prefs.setInt('check_out_hour', _checkOutTime.hour);
    await prefs.setInt('check_out_minute', _checkOutTime.minute);
    await prefs.setInt('break_hour', _breakTime.hour);
    await prefs.setInt('break_minute', _breakTime.minute);
    
    await prefs.setString('alarm_sound', _selectedSound);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(currentMoodThemeProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: currentTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: currentTheme.surfaceColor,
          title: Text('Alarm Settings', style: TextStyle(color: currentTheme.textColor)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: currentTheme.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: currentTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: currentTheme.surfaceColor,
        title: Text('Alarm Settings', style: TextStyle(color: currentTheme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: currentTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: currentTheme.gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.alarm, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder Alarms',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Never miss check-in or check-out',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Check-in alarm
          _buildAlarmCard(
            currentTheme: currentTheme,
            icon: Icons.login,
            title: 'Check-In Reminder',
            description: 'Reminds you to check in',
            isEnabled: _checkInAlarmEnabled,
            time: _checkInTime,
            onToggle: (value) async {
              setState(() => _checkInAlarmEnabled = value);
              await _saveSettings();
              
              if (value) {
                final hasPermission = await PermissionService.requestNotificationPermission(context);
                if (hasPermission) {
                  await _scheduleCheckInAlarm();
                  _showSnackBar('Check-in alarm enabled');
                }
              } else {
                await _alarmService.cancelAlarm(1);
                _showSnackBar('Check-in alarm disabled');
              }
            },
            onTimeChanged: () async {
              final newTime = await _selectTime(_checkInTime);
              if (newTime != null) {
                setState(() => _checkInTime = newTime);
                await _saveSettings();
                if (_checkInAlarmEnabled) {
                  await _scheduleCheckInAlarm();
                }
              }
            },
          ),

          // Check-out alarm
          _buildAlarmCard(
            currentTheme: currentTheme,
            icon: Icons.logout,
            title: 'Check-Out Reminder',
            description: 'Reminds you to check out',
            isEnabled: _checkOutAlarmEnabled,
            time: _checkOutTime,
            onToggle: (value) async {
              setState(() => _checkOutAlarmEnabled = value);
              await _saveSettings();
              
              if (value) {
                final hasPermission = await PermissionService.requestNotificationPermission(context);
                if (hasPermission) {
                  await _scheduleCheckOutAlarm();
                  _showSnackBar('Check-out alarm enabled');
                }
              } else {
                await _alarmService.cancelAlarm(2);
                _showSnackBar('Check-out alarm disabled');
              }
            },
            onTimeChanged: () async {
              final newTime = await _selectTime(_checkOutTime);
              if (newTime != null) {
                setState(() => _checkOutTime = newTime);
                await _saveSettings();
                if (_checkOutAlarmEnabled) {
                  await _scheduleCheckOutAlarm();
                }
              }
            },
          ),

          // Break alarm
          _buildAlarmCard(
            currentTheme: currentTheme,
            icon: Icons.coffee,
            title: 'Break Reminder',
            description: 'Reminds you to take a break',
            isEnabled: _breakAlarmEnabled,
            time: _breakTime,
            onToggle: (value) async {
              setState(() => _breakAlarmEnabled = value);
              await _saveSettings();
              
              if (value) {
                final hasPermission = await PermissionService.requestNotificationPermission(context);
                if (hasPermission) {
                  await _scheduleBreakAlarm();
                  _showSnackBar('Break alarm enabled');
                }
              } else {
                await _alarmService.cancelAlarm(3);
                _showSnackBar('Break alarm disabled');
              }
            },
            onTimeChanged: () async {
              final newTime = await _selectTime(_breakTime);
              if (newTime != null) {
                setState(() => _breakTime = newTime);
                await _saveSettings();
                if (_breakAlarmEnabled) {
                  await _scheduleBreakAlarm();
                }
              }
            },
          ),

          const SizedBox(height: 24),

          // Alarm sound selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note, color: currentTheme.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Alarm Sound',
                      style: TextStyle(
                        color: currentTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSound,
                  dropdownColor: currentTheme.surfaceColor,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: currentTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: currentTheme.textColor),
                  items: _availableSounds.map((sound) {
                    return DropdownMenuItem(
                      value: sound,
                      child: Text(sound),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() => _selectedSound = value);
                      await _saveSettings();
                      _showSnackBar('Alarm sound changed to $value');
                    }
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _alarmService.playAlarmSound();
                    Future.delayed(const Duration(seconds: 3), () {
                      _alarmService.stopAlarmSound();
                    });
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Alarm Sound'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Active alarms
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: currentTheme.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Active Alarms',
                      style: TextStyle(
                        color: currentTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<PendingNotificationRequest>>(
                  future: _alarmService.getScheduledAlarms(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        'No active alarms',
                        style: TextStyle(color: currentTheme.secondaryTextColor),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((alarm) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.alarm, color: currentTheme.accentColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alarm.title ?? 'Alarm',
                                  style: TextStyle(color: currentTheme.textColor, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard({
    required dynamic currentTheme,
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required TimeOfDay time,
    required Function(bool) onToggle,
    required VoidCallback onTimeChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? currentTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: currentTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: currentTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: currentTheme.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                activeColor: currentTheme.primaryColor,
                onChanged: onToggle,
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: onTimeChanged,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: currentTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      time.format(context),
                      style: TextStyle(
                        color: currentTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit, color: currentTheme.secondaryTextColor, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<TimeOfDay?> _selectTime(TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: ref.read(currentMoodThemeProvider).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _scheduleCheckInAlarm() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      _checkInTime.hour,
      _checkInTime.minute,
    );
    await _alarmService.setDailyAlarm(
      id: 1,
      title: '⏰ Time to Check In',
      body: 'Don\'t forget to mark your attendance!',
      hour: _checkInTime.hour,
      minute: _checkInTime.minute,
    );
  }

  Future<void> _scheduleCheckOutAlarm() async {
    await _alarmService.setDailyAlarm(
      id: 2,
      title: '⏰ Time to Check Out',
      body: 'Remember to check out before leaving!',
      hour: _checkOutTime.hour,
      minute: _checkOutTime.minute,
    );
  }

  Future<void> _scheduleBreakAlarm() async {
    await _alarmService.setDailyAlarm(
      id: 3,
      title: '☕ Break Time',
      body: 'Time for a break! Don\'t forget to mark it.',
      hour: _breakTime.hour,
      minute: _breakTime.minute,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ref.read(currentMoodThemeProvider).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
