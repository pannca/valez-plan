import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/alarm_sound_service.dart';
import '../services/system_permission_service.dart';
import '../widgets/permission_warning_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final textMuted = isDark ? const Color(0xFF808E9B) : const Color(0xFF718096);
    final textMain = isDark ? Colors.white : const Color(0xFF2D3748);
    final borderColor = isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Judul Pengaturan
              Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textMain,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Kustomisasi tampilan & sistem aplikasi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 1: TAMPILAN (TEMA)
              _buildSectionHeader('TAMPILAN', textMuted),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF388AF6).withValues(alpha: 0.15)
                                : const Color(0xFFFF9F43).withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: isDark ? const Color(0xFF388AF6) : const Color(0xFFFF9F43),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDark ? 'Mode Malam (Gelap)' : 'Mode Siang (Terang)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDark ? 'Tampilan gelap nyaman di mata' : 'Tampilan terang bersih & jelas',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      activeThumbColor: const Color(0xFF388AF6),
                      activeTrackColor: const Color(0xFF388AF6).withValues(alpha: 0.3),
                      inactiveThumbColor: const Color(0xFFFF9F43),
                      inactiveTrackColor: const Color(0xFFFF9F43).withValues(alpha: 0.3),
                      onChanged: (val) {
                        ThemeService.instance.setDarkMode(val);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 2: SISTEM ALARM
              _buildSectionHeader('SISTEM ALARM & NOTIFIKASI', textMuted),
              const SizedBox(height: 8),

              // Monitor Status Izin Alarm & Sistem
              ValueListenableBuilder<SystemPermissionStatus>(
                valueListenable:
                    SystemPermissionService.instance.statusNotifier,
                builder: (context, status, _) {
                  final isReady = !status.hasAnyIssue;
                  final statusColor = isReady
                      ? const Color(0xFF1DD1A1)
                      : const Color(0xFFFF9F43);

                  return InkWell(
                    onTap: () => PermissionWarningSheet.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isReady
                              ? borderColor
                              : const Color(0xFFFF9F43).withValues(alpha: 0.35),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              isReady
                                  ? Icons.alarm_on_rounded
                                  : Icons.warning_amber_rounded,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alarm Jam Weker',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReady
                                      ? 'Optimal & aktif di sistem Android'
                                      : '${status.issueCount} izin HP perlu diaktifkan (Tap di sini)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isReady ? textMuted : statusColor,
                                    fontWeight: isReady
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isReady ? 'READY' : 'PERIKSA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Kartu Pilihan & Upload Suara Alarm
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFA259FF).withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Color(0xFFA259FF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nada Suara Alarm',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ValueListenableBuilder<String>(
                                valueListenable: AlarmSoundService.instance.soundNameNotifier,
                                builder: (_, soundName, __) {
                                  return Text(
                                    soundName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFA259FF),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Tombol Play / Stop Cuplikan
                        ValueListenableBuilder<bool>(
                          valueListenable: AlarmSoundService.instance.isPlayingPreviewNotifier,
                          builder: (_, isPlaying, __) {
                            return IconButton(
                              tooltip: isPlaying ? 'Berhenti' : 'Putar Cuplikan',
                              onPressed: () => AlarmSoundService.instance.togglePreview(),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                                      : const Color(0xFF388AF6).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                  color: isPlaying ? const Color(0xFFFF5252) : const Color(0xFF388AF6),
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Tombol Upload / Pilih File Audio Sendiri
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF388AF6),
                              side: const BorderSide(color: Color(0xFF388AF6)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              final success = await AlarmSoundService.instance.pickCustomAudio();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF1E272E),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            color: Color(0xFF1DD1A1), size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Suara alarm diubah ke: ${AlarmSoundService.instance.currentSoundName}',
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: const Text(
                              'Pilih Audio Sendiri',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                        ValueListenableBuilder<String>(
                          valueListenable: AlarmSoundService.instance.soundPathNotifier,
                          builder: (_, path, __) {
                            if (path == AlarmSoundService.defaultSoundPath) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: textMuted,
                                ),
                                onPressed: () async {
                                  await AlarmSoundService.instance.resetToDefault();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFF1E272E),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        content: const Text(
                                          'Suara alarm dikembalikan ke default.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset', style: TextStyle(fontSize: 12)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mendukung MP3, WAV, AAC, M4A dari memori HP. File akan disimpan aman di internal aplikasi.',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 3: TENTANG APLIKASI
              _buildSectionHeader('TENTANG', textMuted),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ValezPlan',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: textMain,
                              ),
                            ),
                            Text(
                              'Versi 1.0.0 (Personal Edition)',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aplikasi daily planner & alarm pribadi yang dirancang khusus untuk Valez dengan Structured Timeline style dan offline SQLite storage.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: textMuted,
        ),
      ),
    );
  }
}

