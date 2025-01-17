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
  bool? isRaining = false;

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
      setState(() {
        isRaining = rainStatus;
      });

      if (rainStatus == true) {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.black87),
            ),
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
            buildButton(
              "Expose Clothesline",
              Icons.wb_sunny,
              isServo180,
              () {
                setState(() {
                  isServo180 = true;
                  isServo0 = false; // Reset the other button
                });
                sendToFirebase("Servo", 180);
              },
              mode == "Manual",
            ),

            // Retract Clothesline Button
            buildButton(
              "Retract Clothesline",
              Icons.cloud,
              isServo0,
              () {
                setState(() {
                  isServo0 = true;
                  isServo180 = false; // Reset the other button
                });
                sendToFirebase("Servo", 0);
              },
              mode == "Manual",
            ),

            // Automatic Clothesline Button
            buildButton(
              "Automatic Clothesline",
              Icons.build,
              isAuto,
              () {
                setState(() {
                  isAuto = !isAuto;
                });
                sendToFirebase("Auto", isAuto ? 1 : 0);
              },
              mode == "Automatic",
            ),

            const SizedBox(height: 30),

            // Display GIF based on rain status
            if (isRaining != null)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Image.asset(
                  isRaining!
                      ? 'assets/images/storm.gif'
                      : 'assets/images/sun.gif',
                  height: 150,
                ),
              )
            else
              const Text("Loading weather status..."),
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

  // Helper function to build buttons
  Widget buildButton(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onPressed,
    bool isEnabled,
  ) {
    const double buttonWidth = 220;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: buttonWidth,
        child: ElevatedButton.icon(
          onPressed: isEnabled ? onPressed : null,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(color: Colors.black87),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? Colors.greenAccent
                : const Color.fromARGB(255, 0, 217, 255),
          ),
        ),
      ),
    );
  }
}
