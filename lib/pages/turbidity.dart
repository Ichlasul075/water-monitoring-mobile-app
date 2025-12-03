import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/mqtt_service.dart';

class WaterTurbidityPage extends StatefulWidget {
  const WaterTurbidityPage({Key? key}) : super(key: key);

  @override
  _WaterTurbidityPageState createState() => _WaterTurbidityPageState();
}

class _WaterTurbidityPageState extends State<WaterTurbidityPage> {
  final MqttService _mqttService = MqttService();
  String _turbidityValue = "Loading..."; // Nilai turbidity yang ditampilkan
  List<Map<String, String>> _turbidityHistory = []; // Riwayat turbidity

  @override
  void initState() {
    super.initState();
    _initializeMqtt(); // Menginisialisasi koneksi MQTT
  }

  // Fungsi untuk menginisialisasi koneksi MQTT
  Future<void> _initializeMqtt() async {
    try {
      await _mqttService.connect();
      print("Connected to MQTT");
      await _mqttService.subscribe("Aquadex");

      _mqttService.listenToTopic("Aquadex").listen((payload) {
        try {
          final decodedPayload = json.decode(payload);
          print("Decoded Payload: $decodedPayload");

          final turbidityValue = decodedPayload['Turbidity']?.toString();

          if (turbidityValue != null) {
            setState(() {
              _turbidityValue = "$turbidityValue NTU";

              _turbidityHistory.insert(
                  0, {'Time': _getCurrentTime(), 'Turbidity': _turbidityValue});

              if (_turbidityHistory.length > 10) {
                _turbidityHistory.removeLast();
              }
            });

            print("Turbidity Value: $turbidityValue");
          } else {
            print("Turbidity value is null or missing!");
          }
        } catch (e) {
          print("Error decoding payload: $e");
        }
      });
    } catch (e) {
      print("Error initializing MQTT: $e");
    }
  }

  // Fungsi untuk mendapatkan waktu saat ini dalam format jam:menit AM/PM
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _turbidityValue == "Loading..."
                  ? Text(
                      _turbidityValue, // Teks "Loading..."
                      style: const TextStyle(
                        fontSize:
                            24, // Ukuran teks lebih kecil untuk "Loading..."
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _turbidityValue.split(' ')[0], // Angka turbidity
                          style: const TextStyle(
                            fontSize: 100, // Ukuran angka utama
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "NTU", // Satuan turbidity
                          style: TextStyle(
                            fontSize: 18, // Ukuran lebih kecil untuk satuan
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 8),
              const Text(
                'WATER TURBIDITY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: screenWidth * 0.9,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
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
                        DataColumn(label: Text('Turbidity')),
                      ],
                      rows: _turbidityHistory
                          .map((data) => DataRow(cells: [
                                DataCell(Text(data['Time']!)),
                                DataCell(Text(data['Turbidity']!)),
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
