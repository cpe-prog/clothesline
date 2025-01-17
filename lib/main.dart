import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
  String mode = "Manual"; // Current mode
  bool isAuto = false; // Automatic clothesline state
  bool isServo180 = false; // Servo state (Expose Clothesline)
  bool isServo0 = false; // Servo state (Retract Clothesline)

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
            // Left-Aligned Title
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white),
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
                    style: const TextStyle(color: Colors.white),
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
            const SizedBox(height: 40),
            const Text(
              'Welcome to Clothesline',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 100),

            // Expose Clothesline Button
            Container(
              margin: const EdgeInsets.only(top: 20),
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
                icon: const Icon(Icons.sunny),
                label: const Text(
                  "Expose Clothesline",
                  style: TextStyle(color: Colors.black87), // Dark gray text
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isServo180 ? Colors.green : Colors.blue,
                ),
              ),
            ),

            // Retract Clothesline Button
            Container(
              margin: const EdgeInsets.only(top: 20),
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
                icon: const Icon(Icons.cloud),
                label: const Text(
                  "Retract Clothesline",
                  style: TextStyle(color: Colors.black87), // Dark gray text
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isServo0 ? Colors.green : Colors.blue,
                ),
              ),
            ),

            // Automatic Clothesline Button
            Container(
              margin: const EdgeInsets.only(top: 50),
              child: ElevatedButton.icon(
                onPressed: mode == "Automatic"
                    ? () {
                        setState(() {
                          isAuto = !isAuto;
                        });
                        sendToFirebase("Auto", isAuto ? 1 : 0);
                      }
                    : null,
                icon: const Icon(Icons.settings),
                label: const Text(
                  "Automatic Clothesline",
                  style: TextStyle(color: Colors.black87), // Dark gray text
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAuto ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
