import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const PKMWeatherApp());
}

class PKMWeatherApp extends StatelessWidget {
  const PKMWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Pengabdian Kepada Masyarakat Pengukur Temperatur dan Kelembaban",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? temperature;
  int? humidity;
  String? weatherDescription;
  String? mainWeather;
  double? feelsLike;
  int? pressure;
  int? visibility;
  double? windSpeed;
  int? cloudiness;
  bool loading = false;

  List<String> logs = [];
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initNotification();
    fetchWeatherByGPS();
  }

  // ----------------- INIT NOTIFICATION -----------------
  Future<void> initNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(settings);
  }

  Future<void> showWarningNotification(String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          "warning_channel",
          "Warnings",
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      0,
      "Peringatan Kenyamanan Termal!",
      message,
      details,
    );
  }

  // ----------------- GET GPS LOCATION -----------------
  Future<Position?> getGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  // ----------------- FETCH WEATHER FROM API -----------------
  Future<void> fetchWeatherByGPS() async {
    setState(() => loading = true);

    try {
      Position? pos = await getGPS();
      if (pos == null) {
        setState(() => loading = false);
        // Show error message to user
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Error Lokasi"),
                content: const Text(
                  "Tidak dapat mengakses lokasi. Pastikan GPS diaktifkan dan izin lokasi diberikan.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      final String url =
          "https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&units=metric&appid=4248361f830af0dae4a25702b023fb2c";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Validate data before setting state
        if (data["main"] != null &&
            data["main"]["temp"] != null &&
            data["main"]["humidity"] != null) {
          // Extract weather description and main weather condition for icons
          String description = "N/A";

          if (data["weather"] != null &&
              data["weather"] is List &&
              data["weather"].length > 0) {
            description = data["weather"][0]["description"];
            mainWeather = data["weather"][0]["main"]?.toString() ?? "clear";
            description =
                "${description[0].toUpperCase()}${description.substring(1)}";
          }

          // Extract additional weather data
          double feelsLikeTemp = data["main"]["feels_like"]?.toDouble() ?? 0.0;
          int pressureValue = data["main"]["pressure"]?.toInt() ?? 0;
          int visValue =
              (data["visibility"]?.toInt() ?? 0) ~/ 1000; // Convert to km
          double windSpeedValue = data["wind"]?["speed"]?.toDouble() ?? 0.0;
          int cloudValue = data["clouds"]?["all"]?.toInt() ?? 0;

          setState(() {
            temperature = data["main"]["temp"].toDouble();
            humidity = data["main"]["humidity"].toInt();
            weatherDescription = description;
            feelsLike = feelsLikeTemp;
            pressure = pressureValue;
            visibility = visValue;
            windSpeed = windSpeedValue;
            cloudiness = cloudValue;
            loading = false;
          });

          setState(() {
            logs.add(
              "Temp: ${temperature?.toStringAsFixed(1)}°C | Humidity: $humidity% | $weatherDescription | ${DateTime.now()}",
            );
          });

          // Check for alert conditions
          checkWeatherAlerts();
        } else {
          setState(() => loading = false);
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Error Data"),
                  content: const Text("Data cuaca tidak lengkap dari server."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        }
      } else {
        setState(() => loading = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Error API"),
                content: Text(
                  "Gagal mengambil data cuaca. Kode error: ${response.statusCode}",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text("Terjadi kesalahan: ${e.toString()}"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Check weather alerts and show notifications
  void checkWeatherAlerts() {
    if (temperature != null && temperature! > 30) {
      showWarningNotification(
        "Suhu tinggi! Saat ini: ${temperature!.toStringAsFixed(1)}°C. Pertimbangkan membuka ventilasi.",
      );
    }

    if (humidity != null && humidity! < 40) {
      showWarningNotification(
        "Kelembaban rendah! Saat ini: $humidity%. Tambahkan sumber kelembapan.",
      );
    }
  }

  // Get temperature color based on value
  Color getTemperatureColor() {
    if (temperature == null) return Colors.grey;
    if (temperature! < 18) return Colors.blue; // Cold
    if (temperature! < 25) return Colors.green; // Comfortable
    if (temperature! < 30) return Colors.orange; // Warm
    return Colors.red; // Hot
  }

  // Get weather icon based on main weather condition
  IconData getWeatherIcon() {
    if (mainWeather == null) return Icons.wb_sunny;

    switch (mainWeather!.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
        return Icons.cloud;
      case 'fog':
        return Icons.cloud;
      case 'haze':
        return Icons.cloud;
      case 'dust':
        return Icons.cloud;
      case 'sand':
        return Icons.cloud;
      case 'ash':
        return Icons.cloud;
      case 'squall':
        return Icons.air;
      case 'tornado':
        return Icons.air;
      default:
        return Icons.wb_cloudy;
    }
  }

  // Helper method to build weather detail cards
  Widget _buildWeatherDetail(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blue[50] ?? Colors.blue[100] ?? Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.blue[700] ?? Colors.blue),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800] ?? Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900] ?? Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              getWeatherIcon(),
              color: Colors.blue[800] ?? Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              "Kondisi Saat Ini",
              style: TextStyle(
                fontSize: 20,
                color: Colors.blue[800] ?? Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white70,
        elevation: 2,
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlue.shade200.withOpacity(0.5), Colors.white],
          ),
        ),
        child: loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[700] ?? Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Mengambil data cuaca...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[800] ?? Colors.blue,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                margin: const EdgeInsets.only(top: 10),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Current Conditions Card
                      Card(
                        elevation: 8,
                        shadowColor: Colors.blueGrey,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Main Weather Info Row (Temperature & Humidity)
                              Row(
                                children: [
                                  // Temperature Column
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            getWeatherIcon(),
                                            color: getTemperatureColor(),
                                            size: 48,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            temperature != null
                                                ? "${temperature!.toStringAsFixed(1)}°C"
                                                : "-",
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: getTemperatureColor(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Terasa ${feelsLike != null ? "${feelsLike!.toStringAsFixed(1)}°C" : "-"}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Humidity Column
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.water_drop,
                                            color: Colors.blue,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            humidity != null
                                                ? "$humidity%"
                                                : "-",
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Kelembaban",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                weatherDescription != null &&
                                        weatherDescription != "N/A"
                                    ? "Deskripsi: ${weatherDescription!}"
                                    : "Deskripsi: Tidak Tersedia",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Action Buttons Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue,
                                            Colors.blue[700] ?? Colors.blue,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: fetchWeatherByGPS,
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Ambil Data",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.red[700] ?? Colors.red,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            logs.clear();
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Hapus Riwayat",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Additional Weather Info Grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700] ?? Colors.blue,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Informasi Lengkap",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800] ?? Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                // First row
                                Row(
                                  children: [
                                    _buildWeatherDetail(
                                      Icons.thermostat,
                                      "Sensasi",
                                      feelsLike != null
                                          ? "${feelsLike!.toStringAsFixed(0)}°C"
                                          : "-",
                                    ),
                                    _buildWeatherDetail(
                                      Icons.compress,
                                      "Tekanan",
                                      pressure != null ? "$pressure hPa" : "-",
                                    ),
                                    _buildWeatherDetail(
                                      Icons.visibility,
                                      "Jarak Pandang",
                                      visibility != null
                                          ? "$visibility km"
                                          : "-",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Second row
                                Row(
                                  children: [
                                    _buildWeatherDetail(
                                      Icons.air,
                                      "Angin",
                                      windSpeed != null
                                          ? "${windSpeed!.toStringAsFixed(1)} m/s"
                                          : "-",
                                    ),
                                    _buildWeatherDetail(
                                      Icons.cloud,
                                      "Awan",
                                      cloudiness != null ? "$cloudiness%" : "-",
                                    ),
                                    _buildWeatherDetail(
                                      Icons.water,
                                      "Kelembaban",
                                      humidity != null ? "$humidity%" : "-",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Thermal Comfort Info Card
                      Card(
                        elevation: 8,
                        shadowColor: Colors.orange.withOpacity(0.3),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Edukasi Kenyamanan Termal:",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors.orange[800] ?? Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "• Suhu ideal rumah: 24–27°C\n"
                                "• Kelembaban ideal: 40–60%\n"
                                "• Gunakan ventilasi alami sebelum menyalakan AC\n"
                                "• Hindari penggunaan kipas pada kelembaban sangat rendah",
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // History Section
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.blue[700] ?? Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Riwayat Pengukuran:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800] ?? Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // History List
                      Container(
                        height: logs.isEmpty ? 60 : null,
                        child: logs.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                child: const Text(
                                  "Tidak ada riwayat pengukuran",
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final logEntry = logs[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.blue[50] ??
                                          Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color:
                                                Colors.blue[700] ?? Colors.blue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              logEntry,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    Colors.blue[900] ??
                                                    Colors.blue,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color:
                                                  Colors.red[400] ?? Colors.red,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                logs.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
