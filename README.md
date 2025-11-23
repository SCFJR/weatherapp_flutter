
# Aplikasi Pengukur Temperatur dan Kelembaban

Aplikasi Flutter untuk mengukur temperatur dan kelembaban berbasis lokasi menggunakan API OpenWeatherMap. Aplikasi ini dikembangkan sebagai bagian dari program Pengabdian Kepada Masyarakat (PKM).

## Fitur Utama

1. **Pengambilan Lokasi Otomatis**
   - Aplikasi secara otomatis mendeteksi lokasi pengguna menggunakan GPS
   - Meminta izin lokasi sesuai dengan kebijakan platform

2. **Pengukuran Temperatur dan Kelembaban**
   - Menampilkan temperatur dalam satuan Celsius
   - Menampilkan tingkat kelembaban udara dalam persentase
   - Menyediakan tombol untuk memperbarui data

3. **Sistem Peringatan**
   - Notifikasi otomatis saat suhu melebihi 30°C
   - Notifikasi otomatis saat kelembaban di bawah 40%

4. **Riwayat Pengukuran**
   - Mencatat hasil pengukuran sebelumnya dengan timestamp
   - Menyimpan data secara lokal dalam aplikasi

5. **Edukasi Kenyamanan Termal**
   - Menyediakan informasi tentang suhu dan kelembaban ideal
   - Memberikan tips untuk menciptakan kenyamanan termal

## Instalasi

1. Pastikan Flutter SDK telah terinstal di sistem
2. Clone atau download repository ini
3. Jalankan perintah berikut:
   ```
   flutter pub get
   ```
4. Build dan jalankan aplikasi:
   ```
   flutter run
   ```

## Dependensi

Aplikasi ini menggunakan beberapa paket pihak ketiga:

- `http`: Untuk permintaan API ke OpenWeatherMap
- `geolocator`: Untuk mendapatkan informasi lokasi
- `flutter_local_notifications`: Untuk menampilkan notifikasi lokal
- `cupertino_icons`: Untuk ikon dalam UI

## Struktur Proyek

```
lib/
├── main.dart     // File utama aplikasi
```

## Konfigurasi Platform

### Android
File `android/app/src/main/AndroidManifest.xml` telah dilengkapi dengan izin lokasi dan internet:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Penggunaan API Key
Aplikasi ini menggunakan API OpenWeatherMap dengan API key yang tersimpan dalam kode. Pastikan untuk mengganti API key dengan yang valid jika ingin menggunakan aplikasi ini secara produksi.

## Kontribusi

Silakan fork repository ini dan kirimkan pull request jika Anda ingin berkontribusi pada pengembangan aplikasi ini.

## Lisensi

Proyek ini merupakan bagian dari program Pengabdian Kepada Masyarakat dan dapat digunakan secara bebas untuk tujuan pendidikan dan pengembangan masyarakat.
