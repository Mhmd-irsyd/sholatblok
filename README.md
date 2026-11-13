# SholatBlok 🕌

Aplikasi pengingat jadwal sholat cerdas berbasis Flutter dengan alarm adzan pop-up otomatis di layar kunci (*lock screen*), kalkulasi astronomis offline (Kemenag RI), dan tema elegan *Velvet Rose & Dusty Pink*.

## ✨ Fitur Utama

- **Kalkulasi Waktu Sholat Akurat (Offline)**: Perhitungan waktu sholat otomatis menggunakan koordinat GPS astronomis lokal (metode Kemenag RI / Karachi Shafii) tanpa ketergantungan API eksternal yang lambat.
- **Alarm Pop-Up Layar Kunci (Pure Fullscreen Alarm)**: Layar HP otomatis menyala dan menampilkan antarmuka alarm adzan penuh saat adzan tiba, baik saat layar menyala maupun terkunci.
- **Audio Adzan & Kontrol Volume**: Lantunan suara adzan dialirkan ke `STREAM_MUSIC` sehingga volume dapat diatur langsung menggunakan tombol volume fisik HP.
- **Notifikasi Jadwal Berjalan (*Ongoing Notification*)**: Bilah status menampilkan waktu sholat berikutnya dan hitung mundur secara *real-time*.
- **Cache Lokasi Cerdas**: Jika GPS dinonaktifkan, aplikasi otomatis menggunakan data lokasi terakhir tanpa menampilkan error crash.
- **Pengaturan Suara Kustom**: Opsi suara adzan per waktu sholat (Default, Custom MP3, Hanya Getar, atau Hening).

## 🚀 Memulai

### Prasyarat
- Flutter SDK (3.11+ / stable)
- Android SDK (API level 26+ disarankan)

### Instalasi & Menjalankan
```bash
# Clone repositori
git clone <url-repositori-anda>
cd sholatblok

# Ambil dependencies
flutter pub get

# Jalankan di emulator atau perangkat fisik
flutter run
```

### Build APK Rilis
```bash
flutter build apk --split-per-abi
```

## 📱 Platform yang Didukung
- **Android**: Android 8.0 (API 26) hingga Android 16 (kompatibel dengan HyperOS / MIUI, Samsung One UI, ColorOS, Stock Android).
- **iOS**: Dalam tahap pengembangan/konfigurasi dasar.

---
Dikembangkan dengan ❤️ menggunakan Flutter & Riverpod.
