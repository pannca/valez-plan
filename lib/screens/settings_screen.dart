import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/alarm_sound_service.dart';
import '../services/system_permission_service.dart';
import '../services/tolerance_service.dart';
import '../theme/app_colors.dart';
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
    final cardBg = AppColors.surface(isDark);
    final textMuted = AppColors.muted(isDark);
    final textMain = AppColors.ink(isDark);
    final borderColor = AppColors.border(isDark);
    final accentColor = AppColors.accent(isDark);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),

              // Judul Pengaturan
              Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 1: TAMPILAN (TEMA)
              _buildSectionHeader('TAMPILAN', textMuted),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
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
                            color: AppColors.accentSoft(isDark),
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDark ? 'Mode Gelap' : 'Mode Terang',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
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
                      activeThumbColor: accentColor,
                      activeTrackColor: AppColors.accentSoft(isDark),
                      inactiveThumbColor: AppColors.muted(isDark),
                      inactiveTrackColor: AppColors.surfaceSubtle(isDark),
                      onChanged: (val) async {
                        await ThemeService.instance.setDarkMode(val);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 2: DISIPLIN WAKTU
              _buildSectionHeader('DISIPLIN WAKTU', textMuted),
              const SizedBox(height: 8),

              ValueListenableBuilder<int>(
                valueListenable:
                    ToleranceService.instance.toleranceMinutesNotifier,
                builder: (context, currentTolerance, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
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
                                color: AppColors.accentSoft(isDark),
                              ),
                              child: Icon(
                                Icons.timelapse_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Toleransi Keterlambatan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Batas waktu sebelum jadwal dikunci terlewat',
                                    style: TextStyle(
                                        fontSize: 12, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            (30, '30 mnt'),
                            (60, '60 mnt'),
                            (120, '2 jam'),
                            (-1, 'Akhir hari'),
                          ].map((item) {
                            final isSelected = currentTolerance == item.$1;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: GestureDetector(
                                  onTap: () => ToleranceService.instance
                                      .setTolerance(item.$1),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.accentSoft(isDark)
                                          : AppColors.surfaceSubtle(isDark),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? accentColor
                                            : borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      item.$2,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? accentColor
                                            : textMain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // SECTION 3: SISTEM ALARM
              _buildSectionHeader('ALARM & NOTIFIKASI', textMuted),
              const SizedBox(height: 8),

              // Monitor Status Izin Alarm & Sistem
              ValueListenableBuilder<SystemPermissionStatus>(
                valueListenable:
                    SystemPermissionService.instance.statusNotifier,
                builder: (context, status, _) {
                  final isReady = !status.hasAnyIssue;
                  final statusColor = isReady
                      ? AppColors.success
                      : AppColors.warning;

                  return InkWell(
                    onTap: () => PermissionWarningSheet.show(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isReady
                              ? borderColor
                              : AppColors.statusBorder(AppColors.warning, isDark),
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
                              color: AppColors.statusSoft(statusColor, isDark),
                            ),
                            child: Icon(
                              isReady
                                  ? Icons.verified_user_rounded
                                  : Icons.gpp_maybe_rounded,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Izin Alarm',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReady
                                      ? 'Semua izin aktif'
                                      : '${status.issueCount} izin perlu diaktifkan',
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
                              color: AppColors.statusSoft(statusColor, isDark),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isReady ? 'AKTIF' : 'PERIKSA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
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

              // Kartu Pilihan & Upload Suara Alarm (Bebas Violet, Tegas Netral & Cobalt)
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
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
                            color: AppColors.surfaceSubtle(isDark),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Suara Alarm',
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
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
                                      ? AppColors.statusSoft(AppColors.danger, isDark)
                                      : AppColors.accentSoft(isDark),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                  color: isPlaying ? AppColors.danger : accentColor,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 12),

                    // Tombol Upload / Pilih File Audio Sendiri
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textMain,
                              backgroundColor: AppColors.surfaceSubtle(isDark),
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final success = await AlarmSoundService.instance.pickCustomAudio();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: cardBg,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            color: AppColors.success, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Suara alarm: ${AlarmSoundService.instance.currentSoundName}',
                                            style: TextStyle(
                                                color: textMain, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.upload_file_rounded, size: 18, color: accentColor),
                            label: const Text(
                              'Pilih Audio',
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
                                        backgroundColor: cardBg,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        content: Text(
                                          'Suara default dipulihkan.',
                                          style: TextStyle(color: textMain),
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
                      'Format yang didukung: MP3, WAV, AAC, M4A',
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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
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
                                fontWeight: FontWeight.w800,
                                color: textMain,
                              ),
                            ),
                            Text(
                              'Versi 1.1.0',
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
                      'Daily planner & alarm harian berbasis timeline.',
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

