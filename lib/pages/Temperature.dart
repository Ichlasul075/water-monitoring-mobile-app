import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/mqtt_service.dart';

class TemperaturePage extends StatefulWidget {
  const TemperaturePage({Key? key}) : super(key: key);

  @override
  _TemperaturePageState createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  final MqttService _mqttService = MqttService();
  String _temperature = "Loading..."; // Default text until data is received
  List<Map<String, String>> _temperatureHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeMqtt();
  }

  Future<void> _initializeMqtt() async {
    try {
      // Connect ke broker MQTT
      await _mqttService.connect();
      print("MQTT Connected");

      // Subscribe ke topik "Aquadex"
      await _mqttService.subscribe("Aquadex");

      // Dengarkan data dari topik
      _mqttService.listenToTopic("Aquadex").listen((payload) {
        try {
          // Decode payload JSON
          final decodedPayload = json.decode(payload);

          // Ambil nilai suhu dari JSON
          final temperatureValue = decodedPayload['Suhu'];

          setState(() {
            _temperature = "$temperatureValue°C";

            // Tambahkan data suhu ke dalam history
            _temperatureHistory.insert(0, {
              'Time': _getCurrentTime(),
              'Temperature': _temperature,
            });

            // Membatasi jumlah data di riwayat
            if (_temperatureHistory.length > 10) {
              _temperatureHistory.removeLast();
            }
          });

          print(
              "Temperature Value: $temperatureValue"); // Debugging: Cek nilai suhu di terminal
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
                _temperature,
                style: TextStyle(
                  fontSize: 40, // Ukuran teks lebih kecil
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'TEMPERATURE',
                style: TextStyle(
                  fontSize: 16,
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
                        DataColumn(label: Text('Temperature')),
                      ],
                      rows: _temperatureHistory
                          .map((data) => DataRow(cells: [
                                DataCell(Text(data['Time']!)),
                                DataCell(Text(data['Temperature']!)),
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
