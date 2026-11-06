import 'package:flutter/material.dart';
import '../services/theme_service.dart';

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

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1DD1A1).withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.alarm_on_rounded,
                              color: Color(0xFF1DD1A1),
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
                                  'Aktif mendaftarkan ke sistem Android',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DD1A1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'READY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1DD1A1),
                              ),
                            ),
                          ),
                        ],
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF388AF6).withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF388AF6),
                            size: 22,
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

