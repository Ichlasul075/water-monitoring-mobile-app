import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient _client;
  final String _broker = '76397f75035a455399199a08f3b33bb8.s1.eu.hivemq.cloud';
  final int _port = 8883;
  final String _username = 'Aquadex123';
  final String _password = 'Aquadex123';
  final String _clientId = 'app-client';

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
      print('Subscribed to topic: $topic');
    } else {
      print('Error: Not connected to MQTT broker.');
    }
  }

  // Fungsi untuk mendengarkan data dari topik yang disubscribe
  Stream<String> listenToTopic(String topic) async* {
    if (_client.updates != null) {
      await for (final updates in _client.updates!) {
        for (final MqttReceivedMessage message in updates) {
          if (message.topic == topic) {
            final MqttPublishMessage mqttMessage =
                message.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
                mqttMessage.payload.message);
            print('Received message: $payload');
            yield payload;
          }
        }
      }
    } else {
      throw Exception('MQTT updates stream is null');
    }
  }

  // Fungsi untuk disconnect
  void disconnect() {
    _client.disconnect();
    print('Disconnected from MQTT');
  }
}
