import 'package:flutter/material.dart';
import '../services/language_service.dart';
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
                AppStrings.settingsHeader,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 1: TAMPILAN (TEMA)
              _buildSectionHeader(AppStrings.appearanceSection, textMuted),
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
                              isDark ? AppStrings.darkMode : AppStrings.lightMode,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDark ? AppStrings.darkThemeActive : AppStrings.lightThemeActive,
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

              // SECTION 2: BAHASA (LANGUAGE) - Opsi B (Bottom Sheet)
              _buildSectionHeader(AppStrings.languageSection, textMuted),
              const SizedBox(height: 8),

              ValueListenableBuilder<String>(
                valueListenable: LanguageService.instance.languageNotifier,
                builder: (context, _, __) {
                  return InkWell(
                    onTap: () => _showLanguageSheet(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentSoft(isDark),
                            ),
                            child: Icon(
                              Icons.translate_rounded,
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
                                  AppStrings.appLanguage,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  LanguageService.instance.preferenceLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // SECTION 3: DISIPLIN WAKTU
              _buildSectionHeader(AppStrings.timeDiscipline, textMuted),
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
                                    AppStrings.latenessTolerance,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppStrings.toleranceSubtitle,
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
                            (30, AppStrings.isEn ? '30 min' : '30 mnt'),
                            (60, AppStrings.isEn ? '60 min' : '60 mnt'),
                            (120, AppStrings.isEn ? '2 hrs' : '2 jam'),
                            (-1, AppStrings.endOfDay),
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

              // SECTION 4: SISTEM ALARM
              _buildSectionHeader(AppStrings.systemPermissions, textMuted),
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
                                  AppStrings.isEn
                                      ? 'Alarm Permission Status'
                                      : 'Status Izin Alarm',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReady
                                      ? (AppStrings.isEn
                                          ? 'All permissions active'
                                          : 'Semua izin aktif')
                                      : (AppStrings.isEn
                                          ? '${status.issueCount} permissions need activation'
                                          : '${status.issueCount} izin perlu diaktifkan'),
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
                              isReady
                                  ? (AppStrings.isEn ? 'ACTIVE' : 'AKTIF')
                                  : (AppStrings.isEn ? 'CHECK' : 'PERIKSA'),
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

              // Kartu Pilihan & Upload Suara Alarm
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
                                AppStrings.isEn ? 'Alarm Sound' : 'Suara Alarm',
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
                              tooltip: isPlaying
                                  ? (AppStrings.isEn ? 'Stop' : 'Berhenti')
                                  : (AppStrings.isEn
                                      ? 'Play Preview'
                                      : 'Putar Cuplikan'),
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
                                            '${AppStrings.isEn ? "Alarm sound" : "Suara alarm"}: ${AlarmSoundService.instance.currentSoundName}',
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
                            label: Text(
                              AppStrings.isEn ? 'Choose Audio' : 'Pilih Audio',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                                          AppStrings.isEn
                                              ? 'Default sound restored.'
                                              : 'Suara default dipulihkan.',
                                          style: TextStyle(color: textMain),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: Text(
                                  AppStrings.isEn ? 'Reset' : 'Reset',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.isEn
                          ? 'Supported formats: MP3, WAV, AAC, M4A'
                          : 'Format yang didukung: MP3, WAV, AAC, M4A',
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

              // SECTION 5: TENTANG APLIKASI
              _buildSectionHeader(AppStrings.aboutApp, textMuted),
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
                              '${AppStrings.version} 1.2.0',
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
                      AppStrings.isEn
                          ? 'Timeline-based daily planner & alarm application.'
                          : 'Daily planner & alarm harian berbasis timeline.',
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

  void _showLanguageSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = AppColors.surface(isDark);
    final cardBg = AppColors.surfaceSubtle(isDark);
    final borderColor = AppColors.border(isDark);
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final accentColor = AppColors.accent(isDark);
    final currentPref = LanguageService.instance.currentPreference;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentBorder(isDark),
                      ),
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.selectLanguage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.selectLanguageDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Opsi 1: Ikuti Sistem (System Default)
              _buildLanguageOption(
                ctx: ctx,
                code: 'system',
                title: AppStrings.systemDefault,
                subtitle: AppStrings.systemDefaultDesc,
                badge: '⚙️',
                isSelected: currentPref == 'system',
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                accentColor: accentColor,
                textMain: textMain,
                textMuted: textMuted,
              ),
              const SizedBox(height: 10),

              // Opsi 2: Bahasa Indonesia
              _buildLanguageOption(
                ctx: ctx,
                code: 'id',
                title: AppStrings.indonesian,
                subtitle: AppStrings.indonesianDesc,
                badge: '🇮🇩',
                isSelected: currentPref == 'id',
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                accentColor: accentColor,
                textMain: textMain,
                textMuted: textMuted,
              ),
              const SizedBox(height: 10),

              // Opsi 3: English
              _buildLanguageOption(
                ctx: ctx,
                code: 'en',
                title: AppStrings.english,
                subtitle: AppStrings.englishDesc,
                badge: '🇬🇧',
                isSelected: currentPref == 'en',
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                accentColor: accentColor,
                textMain: textMain,
                textMuted: textMuted,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext ctx,
    required String code,
    required String title,
    required String subtitle,
    required String badge,
    required bool isSelected,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color accentColor,
    required Color textMain,
    required Color textMuted,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(ctx);
        await LanguageService.instance.setLanguage(code);
        if (mounted) setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft(isDark) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(badge, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accentColor : textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: accentColor,
                size: 20,
              )
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
              ),
          ],
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

