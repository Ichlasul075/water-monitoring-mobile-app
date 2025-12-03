import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/mqtt_service.dart';

class WaterPhPage extends StatefulWidget {
  const WaterPhPage({Key? key}) : super(key: key);

  @override
  _WaterPhPageState createState() => _WaterPhPageState();
}

class _WaterPhPageState extends State<WaterPhPage> {
  final MqttService _mqttService = MqttService();
  String _phValue = "Loading..."; // Default value
  List<Map<String, String>> _phHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeMqtt();
  }

  Future<void> _initializeMqtt() async {
    try {
      // Connect to MQTT broker
      await _mqttService.connect();
      print("Connected to MQTT");

      // Subscribe to the "Aquadex" topic
      await _mqttService.subscribe("Aquadex");

      // Listen for data on the "Aquadex" topic
      _mqttService.listenToTopic("Aquadex").listen((payload) {
        try {
          // Decode JSON payload
          final decodedPayload = json.decode(payload);

          // Extract pH value
          final phValue = decodedPayload['pH'];

          setState(() {
            _phValue = "$phValue pH";

            // Add to history
            _phHistory.insert(0, {'Time': _getCurrentTime(), 'pH': _phValue});

            // Limit history to 10 entries
            if (_phHistory.length > 10) {
              _phHistory.removeLast();
            }
          });

          print("pH Value: $phValue"); // Debugging
        } catch (e) {
          print("Error decoding payload: $e");
        }
      });
    } catch (e) {
      print("Error initializing MQTT: $e");
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _phValue,
                style: TextStyle(
                  fontSize: 40, // Ukuran teks lebih kecil
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'WATER PH',
                style: TextStyle(
                  fontSize: 16, // Label fontSize disesuaikan
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('pH')),
                      ],
                      rows: _phHistory
                          .map((data) => DataRow(cells: [
                                DataCell(Text(data['Time']!)),
                                DataCell(Text(data['pH']!)),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
