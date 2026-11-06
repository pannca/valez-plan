import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'database_service.dart';

class AlarmSoundService {
  static final AlarmSoundService instance = AlarmSoundService._init();
  AlarmSoundService._init();

  static const String defaultSoundPath = 'assets/sounds/alarm.mp3';
  static const String defaultSoundName = 'Default Valez Bell';

  String _currentSoundPath = defaultSoundPath;
  String _currentSoundName = defaultSoundName;

  final ValueNotifier<String> soundNameNotifier =
      ValueNotifier<String>(defaultSoundName);
  final ValueNotifier<String> soundPathNotifier =
      ValueNotifier<String>(defaultSoundPath);
  final ValueNotifier<bool> isPlayingPreviewNotifier =
      ValueNotifier<bool>(false);

  final AudioPlayer _previewPlayer = AudioPlayer();

  String get currentSoundPath => _currentSoundPath;
  String get currentSoundName => _currentSoundName;
  bool get isCustomSound => _currentSoundPath != defaultSoundPath;

  // Inisialisasi saat aplikasi pertama dibuka
  Future<void> init() async {
    _previewPlayer.onPlayerComplete.listen((_) {
      isPlayingPreviewNotifier.value = false;
    });

    if (kIsWeb) return;

    try {
      final savedPath =
          await DatabaseService.instance.getSetting('alarm_sound_path');
      final savedName =
          await DatabaseService.instance.getSetting('alarm_sound_name');

      if (savedPath != null && savedPath.isNotEmpty) {
        if (savedPath.startsWith('assets/')) {
          _currentSoundPath = savedPath;
          _currentSoundName = savedName ?? defaultSoundName;
        } else {
          final file = File(savedPath);
          if (await file.exists()) {
            _currentSoundPath = savedPath;
            _currentSoundName = savedName ?? file.uri.pathSegments.last;
          } else {
            // File fisik sudah tidak ada, fallback ke default
            _currentSoundPath = defaultSoundPath;
            _currentSoundName = defaultSoundName;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved alarm sound: $e');
    }

    soundNameNotifier.value = _currentSoundName;
    soundPathNotifier.value = _currentSoundPath;
  }

  // Pilih file audio dari penyimpanan HP (MP3, WAV, AAC, M4A, OGG)
  Future<bool> pickCustomAudio() async {
    try {
      await stopPreview();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = result.files.single;
      final originalPath = file.path;
      if (originalPath == null) return false;

      // Copy file ke folder internal aplikasi agar tidak hilang jika di Downloads terhapus
      final appDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${appDir.path}/alarm_sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final cleanFileName = file.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final targetPath =
          '${soundsDir.path}/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';

      final savedFile = await File(originalPath).copy(targetPath);

      _currentSoundPath = savedFile.path;
      _currentSoundName = file.name;

      soundNameNotifier.value = _currentSoundName;
      soundPathNotifier.value = _currentSoundPath;

      // Simpan ke SQLite
      await DatabaseService.instance
          .setSetting('alarm_sound_path', _currentSoundPath);
      await DatabaseService.instance
          .setSetting('alarm_sound_name', _currentSoundName);

      return true;
    } catch (e) {
      debugPrint('Error picking custom audio: $e');
      return false;
    }
  }

  // Kembalikan ke suara bawaan
  Future<void> resetToDefault() async {
    await stopPreview();

    _currentSoundPath = defaultSoundPath;
    _currentSoundName = defaultSoundName;

    soundNameNotifier.value = _currentSoundName;
    soundPathNotifier.value = _currentSoundPath;

    await DatabaseService.instance
        .setSetting('alarm_sound_path', defaultSoundPath);
    await DatabaseService.instance
        .setSetting('alarm_sound_name', defaultSoundName);
  }

  // Putar atau hentikan cuplikan suara alarm
  Future<void> togglePreview() async {
    if (isPlayingPreviewNotifier.value) {
      await stopPreview();
    } else {
      try {
        isPlayingPreviewNotifier.value = true;
        if (_currentSoundPath.startsWith('assets/')) {
          final assetRelative = _currentSoundPath.replaceFirst('assets/', '');
          await _previewPlayer.play(AssetSource(assetRelative));
        } else {
          await _previewPlayer.play(DeviceFileSource(_currentSoundPath));
        }
      } catch (e) {
        debugPrint('Error playing preview: $e');
        isPlayingPreviewNotifier.value = false;
      }
    }
  }

  // Hentikan cuplikan suara
  Future<void> stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    isPlayingPreviewNotifier.value = false;
  }

  void dispose() {
    _previewPlayer.dispose();
  }
}
