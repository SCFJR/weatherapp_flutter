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

    Position? pos = await getGPS();
    if (pos == null) {
      setState(() => loading = false);
      return;
    }

    final String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&units=metric&appid=4248361f830af0dae4a25702b023fb2c";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    setState(() {
      temperature = data["main"]["temp"].toDouble();
      humidity = data["main"]["humidity"].toInt();
      loading = false;
    });

    setState(() {
      logs.add(
        "Temp: ${temperature}°C | Humidity: ${humidity}% | ${DateTime.now()}",
      );
    });

    if (temperature != null && temperature! > 30) {
      showWarningNotification("Suhu tinggi! Pertimbangkan membuka ventilasi.");
    }

    if (humidity != null && humidity! < 40) {
      showWarningNotification(
        "Kelembaban rendah! Tambahkan sumber kelembapan.",
      );
    }
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pengabdian Kepada Masyarakat (PKM) Temperatur dan Kelembaban",
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 4,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "Kondisi Saat Ini",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            temperature != null
                                ? "${temperature!.toStringAsFixed(1)}°C"
                                : "-",
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            humidity != null ? "$humidity %" : "-",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: fetchWeatherByGPS,
                            child: const Text("Ambil Data Ulang"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ----------------- EDUKASI -----------------
                  Card(
                    color: Colors.yellow[100],
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Edukasi Kenyamanan Termal:\n"
                        "- Suhu ideal rumah: 24–27°C\n"
                        "- Kelembaban ideal: 40–60%\n"
                        "- Gunakan ventilasi alami sebelum menyalakan AC\n"
                        "- Hindari penggunaan kipas pada kelembaban sangat rendah",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Riwayat Pengukuran:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...logs.map(
                    (e) => ListTile(
                      title: Text(e),
                      leading: const Icon(Icons.history),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
