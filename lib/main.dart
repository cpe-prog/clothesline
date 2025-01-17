import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clothesline Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 217, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Clothesline Control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  String mode = "Manual"; // Dropdown mode
  bool isAuto = false; // Automatic clothesline state
  bool isServo180 = false; // Servo state for "Expose Clothesline"
  bool isServo0 = false; // Servo state for "Retract Clothesline"

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    listenToRainStatus();
  }

  // Initialize local notifications
  void initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show a notification
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'rain_channel', // Channel ID
      'Rain Alerts', // Channel name
      channelDescription: 'Notifications for rain alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformDetails,
    );
  }

  // Listen for 'rain' changes in Firebase Realtime Database
  void listenToRainStatus() {
    _database.child('Rain').onValue.listen((event) {
      final rainStatus = event.snapshot.value as bool?;
      if (rainStatus == true) {
        // Show notification if 'rain' is true
        showNotification('It\'s Raining!', 'Please retract your clothesline.');
      }
    });
  }

  // Send data to Firebase
  Future<void> sendToFirebase(String key, dynamic value) async {
    await _database.child(key).set(value);
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 220;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left-Aligned Title
            Text(
              widget.title,
              style: const TextStyle(color: Colors.black87),
            ),

            // Right-Aligned Dropdown
            DropdownButton<String>(
              value: mode,
              dropdownColor: Colors.blue,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    mode = newValue;
                    if (mode == "Manual") {
                      isAuto = false; // Reset relay state
                    }
                  });
                }
              },
              items: ["Manual", "Automatic"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text(
              'Welcome to Clothesline',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 50),

            // Expose Clothesline Button
            Container(
                margin: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    onPressed: mode == "Manual"
                        ? () {
                            setState(() {
                              isServo180 = true;
                              isServo0 = false; // Reset the other button
                            });
                            sendToFirebase("Servo", 180);
                          }
                        : null,
                    icon: const Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                    ), // Sun icon
                    label: const Text(
                      "Expose Clothesline",
                      style: TextStyle(
                        color: Colors.black87,
                      ), // Dark gray text
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isServo180
                          ? Colors.greenAccent
                          : const Color.fromARGB(255, 0, 217, 255),
                    ),
                  ),
                )),

            // Retract Clothesline Button
            Container(
                margin: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    onPressed: mode == "Manual"
                        ? () {
                            setState(() {
                              isServo0 = true;
                              isServo180 = false; // Reset the other button
                            });
                            sendToFirebase("Servo", 0);
                          }
                        : null,
                    icon: const Icon(
                      Icons.cloud,
                      color: Colors.white,
                    ), // Cloud icon
                    label: const Text(
                      "Retract Clothesline",
                      style: TextStyle(color: Colors.black87), // Dark gray text
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isServo0
                            ? Colors.greenAccent
                            : const Color.fromARGB(255, 0, 217, 255)),
                  ),
                )),

            // Automatic Clothesline Button
            Container(
                margin: const EdgeInsets.only(top: 50),
                child: SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    onPressed: mode == "Automatic"
                        ? () {
                            setState(() {
                              isAuto = !isAuto;
                            });
                            sendToFirebase("Auto", isAuto ? 1 : 0);
                          }
                        : null,
                    icon: const Icon(
                      Icons.build,
                      color: Colors.white,
                    ), // Tools icon
                    label: const Text(
                      "Automatic Clothesline",
                      style: TextStyle(color: Colors.black87), // Dark gray text
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isAuto
                            ? Colors.greenAccent
                            : const Color.fromARGB(255, 0, 217, 255)),
                  ),
                )),
            const SizedBox(height: 150),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color.fromARGB(255, 0, 217, 255),
        child: const Text(
          '© 2025 Clothesline App - All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ),
    );
  }
}
