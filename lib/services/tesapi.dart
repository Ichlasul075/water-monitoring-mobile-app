import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class MqttService {
  late MqttServerClient _client;
  final String _broker = '76397f75035a455399199a08f3b33bb8.s1.eu.hivemq.cloud';
  final int _port = 8883;
  final String _username = 'Aquadex123';
  final String _password = 'Aquadex123';
  final String _clientId = 'app-client';

  String latestMessage = '';

  // Fungsi untuk menghubungkan ke broker MQTT
  Future<void> connect() async {
    _client = MqttServerClient(_broker, _clientId);
    _client.port = _port;
    _client.logging(on: true);
    _client.secure = true;

    final connMessage = MqttConnectMessage()
        .authenticateAs(_username, _password)
        .withClientIdentifier(_clientId)
        .startClean()
        .withWillTopic('Aquadex')
        .withWillMessage('Disconnected')
        .withWillQos(MqttQos.atMostOnce);

    _client.connectionMessage = connMessage;

    try {
      final connectionStatus = await _client.connect();
      if (connectionStatus?.state == MqttConnectionState.connected) {
        print('Connected to HiveMQ');
      } else {
        print('Failed to connect: ${connectionStatus?.state}');
      }
    } catch (e) {
      print('Error connecting to MQTT: $e');
    }
  }

  // Fungsi untuk subscribe ke topik tertentu
  Future<void> subscribe(String topic) async {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atMostOnce);
      _client.updates?.listen((updates) {
        for (final MqttReceivedMessage message in updates) {
          if (message.topic == topic) {
            final MqttPublishMessage mqttMessage =
                message.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
                mqttMessage.payload.message);
            latestMessage = payload; // Simpan pesan terakhir
            print('Received message: $payload');
          }
        }
      });
      print('Subscribed to topic: $topic');
    } else {
      print('Error: Not connected to MQTT broker.');
    }
  }

  // Fungsi untuk disconnect
  void disconnect() {
    _client.disconnect();
    print('Disconnected from MQTT');
  }
}

// Fungsi untuk membuat handler API
Handler createHandler(MqttService mqttService) {
  return (Request request) {
    // Kembalikan data dalam format JSON
    final data = {'latestMessage': mqttService.latestMessage};
    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  };
}

void main() async {
  final mqttService = MqttService();
  await mqttService.connect();
  await mqttService.subscribe('Aquadex/data'); // Topik yang ingin Anda pantau

  // Mulai server HTTP
  final handler = createHandler(mqttService);
  final server = await shelf_io.serve(handler, 'localhost', 8080);

  print('Server listening on http://${server.address.host}:${server.port}');
}
