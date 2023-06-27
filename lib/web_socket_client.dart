import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketClient {
  static WebSocketClient? _instance;
  IOWebSocketChannel? _client;
  bool _isClientAdded = false;

  bool _isConnected = false;
  bool get isSocketConnected => _isConnected;

  final _heartbeatInterval = 10;
  final _reconnectIntervalMs = 1000;
  int _reconnectCount = 120;
  final _sendBuffer = Queue();
  Timer? _heartBeatTimer, _reconnectTimer;
  static const _endPoint = "wss://ws.postman-echo.com/raw";

  static WebSocketClient getInstance() => _instance ??= WebSocketClient();

  static void Function(dynamic)? onData;

  Future<void> connectToSocket() async {
    if (!_isConnected) {
      WebSocket.connect(_endPoint, compression: CompressionOptions.compressionOff)
          .then((WebSocket socket) async {
        _client = IOWebSocketChannel(socket);
        if (_client != null) {
          _reconnectCount = 120;
          _reconnectTimer?.cancel();
          _isConnected = true;
          if(!_isClientAdded) {
            _isClientAdded = true;
            _push("Socket Added");
          }
          _startHeartBeatTimer();
          _listenToMessage();
          while (_sendBuffer.isNotEmpty) {
            String text = _sendBuffer.first;
            _sendBuffer.remove(text);
            _push(text);
          }
        }
      }).catchError((err) => debugPrint("connection Error $err"));
    }
  }

  Future<void> _reconnect() async {
    if ((_reconnectTimer == null || _reconnectTimer?.isActive == false) &&
        _reconnectCount > 0) {
      _isClientAdded = false;
      _reconnectTimer = Timer.periodic(
          Duration(milliseconds: _reconnectIntervalMs), (Timer timer) async {
        debugPrint("reconnecting ${timer.tick}");
        if (_reconnectCount == 0) {
          _reconnectTimer?.cancel();
          return;
        }
        await connectToSocket();
        _reconnectCount--;
      });
    }
  }

  void _listenToMessage() {
    _client?.stream.listen(onData, onDone: () {
      disconnect();
      _reconnect();
    });
  }

  void subscribe(String text, {bool unsubscribeAllSubscribed = false}) {
    _push(text);
  }

  _startHeartBeatTimer() {
    _heartBeatTimer?.cancel();
    _heartBeatTimer =
        Timer.periodic(Duration(seconds: _heartbeatInterval), (Timer timer) {
      _client?.sink.add("ping_count${timer.tick}");
    });
  }

  _push(String text) {
    if (_isConnected) {
      _client?.sink.add(text);
    } else {
      _sendBuffer.add(text);
    }
  }

  disconnect() {
    debugPrint("disconnected");
    _client?.sink.close(status.goingAway);
    _heartBeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _isConnected = false;
    _isClientAdded = false;
  }

  int _fromBytesToInt32(List<int> elements) {
    ByteBuffer buffer = Int8List.fromList(elements).buffer;
    ByteData byteData = ByteData.view(buffer);
    return byteData.getInt32(0);
  }

  int _fromBytesToInt64(List<int> elements) {
    ByteBuffer buffer = Int8List.fromList(elements).buffer;
    ByteData byteData = ByteData.view(buffer);
    return byteData.getInt64(0);
  }
}
