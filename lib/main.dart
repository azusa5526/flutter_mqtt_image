/////////////////////////////////////////////////////////////////
/*
  AWS IoT | Flutter MQTT Client App [Full Version]
  Video Tutorial: https://youtu.be/aY7i0xnQW54
  Created by Eric N. (ThatProject)
*/
/////////////////////////////////////////////////////////////////
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';
import 'model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MQTT ESP32CAM VIEWER',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: MQTTClient(),
    );
  }
}

class MQTTClient extends StatefulWidget {
  const MQTTClient({Key? key}) : super(key: key);

  @override
  _MQTTClientState createState() => _MQTTClientState();
}

MqttServerClient client = MqttServerClient('localhost', '');

class _MQTTClientState extends State<MQTTClient> {
  String statusText = "Status Text";
  bool isConnected = false;
  bool isStreaming = false;
  bool isFlashing = false;
  TextEditingController idTextController = TextEditingController();
  TextEditingController serverClientController = TextEditingController();
  TextEditingController topicPreController = TextEditingController();
  StreamController<MqttMessage> cameraStreamController = StreamController();

  @override
  void initState() {
    super.initState();
    idTextController.text = 'Default';
    serverClientController.text = '192.168.12.18';
    topicPreController.text = 'topicPreTest';
  }

  @override
  void dispose() {
    idTextController.dispose();
    serverClientController.dispose();
    topicPreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    final bool hasShortWidth = width < 600;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [header(), body(hasShortWidth), footer()],
        ),
      ),
    );
  }

  Widget header() {
    return Expanded(
      child: Container(
        child: Center(
          child: Text(
            'ESP32CAM Viewer',
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      flex: 1,
    );
  }

  Widget body(bool hasShortWidth) {
    return Expanded(
      child: Container(
        child: hasShortWidth
            ? Column(
                children: [bodyMenu(), Expanded(child: bodySteam())],
              )
            : Row(
                children: [
                  Expanded(
                    child: bodyMenu(),
                    flex: 2,
                  ),
                  Expanded(
                    child: bodySteam(),
                    flex: 8,
                  )
                ],
              ),
      ),
      flex: 20,
    );
  }

  Widget bodyMenu() {
    return Container(
      color: Colors.black26,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
                onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 28),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextField(
                                  enabled: !isConnected,
                                  controller: idTextController,
                                  decoration: InputDecoration(
                                    border: UnderlineInputBorder(),
                                    labelText: 'MQTT Client Id',
                                    labelStyle: TextStyle(fontSize: 10),
                                  )),
                              TextField(
                                  enabled: !isConnected,
                                  controller: serverClientController,
                                  decoration: InputDecoration(
                                    border: UnderlineInputBorder(),
                                    labelText: 'Server address',
                                    labelStyle: TextStyle(fontSize: 10),
                                  )),
                              TextField(
                                  enabled: !isConnected,
                                  controller: topicPreController,
                                  decoration: InputDecoration(
                                    border: UnderlineInputBorder(),
                                    labelText: 'Topic pre',
                                    labelStyle: TextStyle(fontSize: 10),
                                  )),
                              Padding(
                                padding: EdgeInsets.only(top: 20.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                          onPressed: isConnected
                                              ? null
                                              : () async {
                                                  await _connect();
                                                  Navigator.of(context).pop();
                                                },
                                          child: Text('Connect')),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: ElevatedButton(
                                          onPressed: isConnected
                                              ? () {
                                                  _disconnect();
                                                  Navigator.of(context).pop();
                                                }
                                              : null,
                                          child: Text('Disconnect')),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                child: Text('Connect options')),
          ),
          Container()
        ],
      ),
    );
  }

  Widget bodySteam() {
    return Container(
      color: Colors.black,
      child: StreamBuilder(
        stream: cameraStreamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16.0, // 宽度
                  height: 16.0, // 高度
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16.0),
                Text(
                  'Waiting for streaming...',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ));
          } else {
            final mqttReceivedMessages = snapshot.data as MqttMessage;

            final recMess = mqttReceivedMessages as MqttPublishMessage;

            return Image.memory(
              Uint8List.view(recMess.payload.message.buffer, 0,
                  recMess.payload.message.length),
              gaplessPlayback: true,
            );
          }
        },
      ),
    );
  }

  Widget footer() {
    return Expanded(
      child: Container(
          padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
          child: Column(
            children: [
              Expanded(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                        onPressed: isConnected ? _onStreamControlClick : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isStreaming ? Colors.green : Colors.red),
                        child: Text(
                          'Stream',
                        )),
                  ),
                  SizedBox(
                    width: 12.0,
                  ),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: isConnected ? _onFlashControlClick : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFlashing ? Colors.green : Colors.red),
                        child: Text('Flash')),
                  )
                ],
              )),
              Expanded(
                  child: Container(
                alignment: Alignment.centerRight,
                child: Text(
                  statusText,
                  style: TextStyle(
                      fontWeight: FontWeight.normal, color: Colors.amberAccent),
                ),
              )),
            ],
          )),
      flex: 3,
    );
  }

  _connect() async {
    if (idTextController.text.trim().isNotEmpty &&
        serverClientController.text.trim().isNotEmpty &&
        topicPreController.text.trim().isNotEmpty) {
      _disconnect();
      client.server = serverClientController.text.trim();

      isConnected = await mqttConnect(idTextController.text.trim(),
          '${topicPreController.text.trim()}/camera');
    }
  }

  _disconnect() {
    client.disconnect();
  }

  _onStreamControlClick() {
    String topicPre = topicPreController.text.trim();
    if (topicPre.isEmpty) return;

    var params = {'v': !isStreaming};
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(params));

    client.publishMessage(
        '${topicPre}/remote', MqttQos.atLeastOnce, builder.payload!);
  }

  _onFlashControlClick() {
    String topicPre = topicPreController.text.trim();
    if (topicPre.isEmpty) return;

    var params = {'f': !isFlashing};
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(params));
    client.publishMessage(
        '${topicPre}/remote', MqttQos.atLeastOnce, builder.payload!);
  }

  Future<bool> mqttConnect(String uniqueId, String topic) async {
    setStatus("Connecting MQTT Broker");

    // After adding your certificates to the pubspec.yaml, you can use Security Context.
    //
    // ByteData rootCA = await rootBundle.load('assets/certs/RootCA.pem');
    // ByteData deviceCert =
    //     await rootBundle.load('assets/certs/DeviceCertificate.crt');
    // ByteData privateKey = await rootBundle.load('assets/certs/Private.key');
    //
    // SecurityContext context = SecurityContext.defaultContext;
    // context.setClientAuthoritiesBytes(rootCA.buffer.asUint8List());
    // context.useCertificateChainBytes(deviceCert.buffer.asUint8List());
    // context.usePrivateKeyBytes(privateKey.buffer.asUint8List());
    //
    // client.securityContext = context;

    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.port = 1883;
    client.secure = false;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.pongCallback = pong;

    final MqttConnectMessage connMess =
        MqttConnectMessage().withClientIdentifier(uniqueId).startClean();
    client.connectionMessage = connMess;

    await client.connect();
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to Server Successfully!");
    } else {
      return false;
    }

    client.subscribe(topic, MqttQos.atMostOnce);
    client.subscribe(
        '${topicPreController.text.trim()}/status', MqttQos.atMostOnce);

    client.updates?.listen((event) {
      switch (event[0].topic) {
        case 'topicPreTest/camera':
          cameraStreamController.add(event[0].payload);
          break;
        case 'topicPreTest/status':
          final publishMessage = event[0].payload as MqttPublishMessage;
          String jsonString =
              new String.fromCharCodes(publishMessage.payload.message);
          final ControlOptions options =
              ControlOptions.fromJson(json.decode(jsonString));
          log(jsonString);

          setState(() {
            if (options.v != null) isStreaming = options.v as bool;
            if (options.f != null) isFlashing = options.f as bool;
          });
          break;
        default:
          log('Unsupported event');
      }
    });

    return true;
  }

  void setStatus(String content) {
    setState(() {
      statusText = content;
    });
  }

  void onConnected() {
    setStatus("Client connection was successful");
  }

  void onDisconnected() {
    setStatus("Client Disconnected");
    isConnected = false;
  }

  void pong() {
    print('Ping response client callback invoked');
  }
}
