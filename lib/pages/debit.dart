import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/mqtt_service.dart';

class IncomingDebitPage extends StatefulWidget {
  const IncomingDebitPage({Key? key}) : super(key: key);

  @override
  _IncomingDebitPageState createState() => _IncomingDebitPageState();
}

class _IncomingDebitPageState extends State<IncomingDebitPage> {
  final MqttService _mqttService = MqttService();
  String _debitValue = "Loading..."; // Menampilkan nilai debit yang diterima
  List<Map<String, String>> _debitHistory = []; // Riwayat debit

  @override
  void initState() {
    super.initState();
    _initializeMqtt(); // Menginisialisasi koneksi MQTT
  }

  Future<void> _initializeMqtt() async {
    try {
      await _mqttService.connect();
      print("Connected to MQTT");
      await _mqttService.subscribe("Aquadex");
      _mqttService.listenToTopic("Aquadex").listen((payload) {
        try {
          final decodedPayload = json.decode(payload);
          final debitValue = decodedPayload['FlowRate'];
          if (debitValue != null) {
            final debit = (debitValue is String)
                ? double.tryParse(debitValue)
                : debitValue is num
                    ? debitValue.toDouble()
                    : null;

            if (debit != null) {
              setState(() {
                _debitValue = debit.toStringAsFixed(2); // Format angka
                _debitHistory.insert(
                    0, {'Time': _getCurrentTime(), 'Debit': _debitValue});

                if (_debitHistory.length > 10) {
                  _debitHistory.removeLast();
                }
              });
            }
          }
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display nilai debit
              _debitValue == "Loading..."
                  ? Text(
                      _debitValue,
                      style: const TextStyle(
                        fontSize:
                            24, // Ukuran lebih kecil untuk teks "Loading..."
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _debitValue,
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "L/min",
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
                'INCOMING DEBIT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 50),

              // Riwayat debit
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
                        DataColumn(label: Text('Debit (L/min)')),
                      ],
                      rows: _debitHistory
                          .map((data) => DataRow(cells: [
                                DataCell(Text(data['Time']!)),
                                DataCell(Text(data['Debit']!)),
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
