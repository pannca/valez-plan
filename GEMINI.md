# ValezPlan - Project Rules & Guidelines

## 1. Aturan Git & Version Control (PENTING)
- **DILARANG KERAS** melakukan `git commit` atau `git push` secara mandiri / otomatis tanpa instruksi eksplisit dari USER.
- Setiap kali menyelesaikan pekerjaan, perubahan kode **hanya boleh disimpan di working directory (file lokal)**.
- Tunggu perintah spesifik dari USER (seperti "commit", "push", atau "commit dan push") sebelum mengeksekusi git commit / git push.

## 2. Standar Kualitas Kode & Desain
- **Design System:** Gunakan satu pusat referensi warna (`AppColors` di `lib/theme/app_colors.dart`). Pertahankan gaya modern, minimalis, dan bebas dari warna pelangi yang berlebihan.
- **Dukungan Tema:** Pastikan setiap komponen baru atau modifikasi mendukung Dark Mode dan Light Mode secara konsisten dan status tema tersimpan persisten di SQLite.
- **Verifikasi:** Selalu jalankan `flutter analyze --no-pub` untuk memastikan tidak ada error, lint warning, atau regresi kode.
- **Disiplin Jadwal & Toleransi:** Jadwal yang sudah selesai (`isCompleted == true`) atau melewati batas toleransi (`isPlanExpired == true`) harus tetap terkunci.
