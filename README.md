
# Flutter GPS Location App

Aplikasi Flutter sederhana untuk memperoleh **koordinat lokasi pengguna (latitude & longitude)** serta mengonversinya menjadi **alamat lengkap** menggunakan package `geolocator` dan `geocoding`.

---

## 📌 Fitur Utama

### ✅ 1. Mendapatkan Lokasi Saat Ini
- Mengambil posisi GPS real–time dari perangkat.
- Menggunakan:
  ```dart
  Geolocator.getCurrentPosition()
  ```
- Hasil ditampilkan dalam format:
  ```
  Latitude: xx.xxxxxx
  Longitude: yy.yyyyyy
  ```

---

### ✅ 2. Request Permission Lokasi
- Mengecek status permission sebelum akses GPS.
- Jika belum diizinkan, aplikasi meminta izin otomatis.
- Mencegah error akses lokasi tanpa izin.

---

### ✅ 3. Reverse Geocoding (Koordinat → Alamat)
- Mengubah koordinat menjadi alamat manusiawi.
- Menggunakan:
  ```dart
  placemarkFromCoordinates()
  ```
- Menampilkan informasi seperti:
  - Nama jalan
  - Kota
  - Kecamatan
  - Negara

---

### ✅ 4. UI Sederhana & Responsif
- `AppBar` dengan teks putih **bold**
- Tombol untuk mengambil lokasi (`ElevatedButton`)
- Menampilkan hasil lokasi & alamat dalam `Column`

---

## 🧠 Cara Kerja Aplikasi

1. User menekan tombol **"Get Location"**
2. App memeriksa permission lokasi
3. Jika diizinkan, GPS membaca koordinat
4. Koordinat dikonversi menjadi alamat
5. Hasil ditampilkan pada layar

Flow inti dalam kode:

```dart
Position position = await Geolocator.getCurrentPosition();
List<Placemark> placemark = await placemarkFromCoordinates(
  position.latitude,
  position.longitude,
);
```

---

## 📂 Struktur File

```
lib/
└── main.dart   # Seluruh logic UI & GPS berada di sini
```

---

## 🔧 Dependency yang Digunakan

Tambahkan pada `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.0
```

Lalu jalankan:

```
flutter pub get
```

---

## 📱 Permission yang Diperlukan

### Android – `android/app/src/main/AndroidManifest.xml`
Tambahkan:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS – `ios/Runner/Info.plist`
Tambahkan:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app requires location access.</string>
```

---

## ▶️ Menjalankan Aplikasi

```
flutter run
```

Tekan tombol **Get Location** untuk menampilkan data.

---

## 📌 Catatan Tambahan
- Pastikan GPS aktif
- Emulator Android harus menggunakan **Google Play image**
- Pada iOS, hanya dapat tes lokasi melalui device real atau simulator dengan lokasi simulasi

---

## ✅ Status
Project siap dikembangkan lebih lanjut — seperti:
- Menampilkan lokasi di Google Maps
- Auto-refresh location stream
- Menyimpan riwayat lokasi
