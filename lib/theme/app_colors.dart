import 'package:flutter/material.dart';

/// Satu-satunya pusat referensi warna (Single Source of Truth) untuk ValezPlan.
/// Mengikuti aturan design-taste-frontend:
/// - 90-95% permukaan netral tegas (Deep Slate di Dark Mode, Cool Grey di Light Mode).
/// - 1 warna aksen utama (Cobalt Blue) untuk aksi utama, status terpilih, dan fokus.
/// - Bebas warna pelangi & bebas ungu/violet.
/// - Warna semantik (Success, Warning, Danger) hanya untuk status fungsional.
class AppColors {
  AppColors._();

  // ===========================================================================
  // 1. PALET NETRAL - DARK MODE (blue-black-cornflower)
  // ===========================================================================
  static const Color bgDark = Color(0xFF0A0D14);
  static const Color surfaceDark = Color(0xFF131824);
  static const Color surfaceSubtleDark = Color(0xFF1A2130);
  static const Color borderDark = Color(0xFF222B3D);
  static const Color inkDark = Color(0xFFE9EDF3);
  static const Color mutedDark = Color(0xFF8A94A6);
  static const Color faintDark = Color(0xFF525C6E);

  // ===========================================================================
  // 2. PALET NETRAL - LIGHT MODE (cool-grey-cobalt)
  // ===========================================================================
  static const Color bgLight = Color(0xFFEEF0F3);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSubtleLight = Color(0xFFE2E5EA);
  static const Color borderLight = Color(0xFFD5DAE2);
  static const Color inkLight = Color(0xFF0B0C0E);
  static const Color mutedLight = Color(0xFF5A6270);
  static const Color faintLight = Color(0xFF949CA8);

  // ===========================================================================
  // 3. SATU AKSEN UTAMA (COBALT BLUE)
  // ===========================================================================
  static const Color accentDark = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF1F2DE6);
  static const Color accentPrimary = Color(0xFF2563EB);

  // ===========================================================================
  // 4. WARNA SEMANTIK TEGAS (Hanya untuk Status Fungsional)
  // ===========================================================================
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // ===========================================================================
  // 5. HELPER TOKEN KONTEKSTUAL (Dark / Light)
  // ===========================================================================
  static Color bg(bool isDark) => isDark ? bgDark : bgLight;
  static Color surface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color surfaceSubtle(bool isDark) =>
      isDark ? surfaceSubtleDark : surfaceSubtleLight;
  static Color border(bool isDark) => isDark ? borderDark : borderLight;
  static Color ink(bool isDark) => isDark ? inkDark : inkLight;
  static Color muted(bool isDark) => isDark ? mutedDark : mutedLight;
  static Color faint(bool isDark) => isDark ? faintDark : faintLight;

  static Color accent(bool isDark) => isDark ? accentDark : accentLight;

  static Color accentSoft(bool isDark) =>
      accent(isDark).withValues(alpha: isDark ? 0.14 : 0.10);

  static Color accentBorder(bool isDark) =>
      accent(isDark).withValues(alpha: isDark ? 0.35 : 0.25);

  static Color statusSoft(Color statusColor, bool isDark) =>
      statusColor.withValues(alpha: isDark ? 0.14 : 0.10);

  static Color statusBorder(Color statusColor, bool isDark) =>
      statusColor.withValues(alpha: isDark ? 0.35 : 0.28);

  // ===========================================================================
  // 6. KATEGORI: IKON TEGAS & SKALA TONAL MONOKROM/COBALT (Bebas Pelangi)
  // ===========================================================================
  static const List<String> categories = [
    'Kerja',
    'Pribadi',
    'Kesehatan',
  ];

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kerja':
      case 'belajar':
        return Icons.business_center_rounded;
      case 'pribadi':
      case 'ibadah':
      case 'santai':
        return Icons.person_rounded;
      case 'kesehatan':
      case 'istirahat':
        return Icons.spa_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  /// Skala tonal Cobalt & Slate untuk grafik distribusi (tanpa warna-warni pelangi)
  static Color categoryTone(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'kerja':
      case 'belajar':
        return isDark ? const Color(0xFF3B82F6) : const Color(0xFF1F2DE6);
      case 'pribadi':
      case 'ibadah':
      case 'santai':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case 'kesehatan':
      case 'istirahat':
        return isDark ? const Color(0xFF93C5FD) : const Color(0xFF38BDF8);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    }
  }
}
