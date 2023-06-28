import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_example/message.dart';
import 'package:web_socket_example/on_data_listener.dart';
import 'package:web_socket_example/serializable.dart';
import 'package:web_socket_example/socket_entry.dart';
import 'package:web_socket_example/utill.dart';
import 'package:web_socket_example/ws_event.dart';

class WebSocketClient implements OnDataListener {
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
  static String _endPoint = "ws://192.168.29.235:3000";

  static WebSocketClient getInstance(String userId) {
    _endPoint = "$_endPoint/$userId";
    if (_instance != null) return _instance!;
    return WebSocketClient();
  }

  Future<void> connectToSocket() async {
    if (!_isConnected) {
      WebSocket.connect(_endPoint,
              compression: CompressionOptions.compressionDefault)
          .then((WebSocket socket) async {
        _client = IOWebSocketChannel(socket);
        if (_client != null) {
          _reconnectCount = 120;
          _reconnectTimer?.cancel();
          _isConnected = true;
          if (!_isClientAdded) {
            _isClientAdded = true;
            subscribe(SocketEntry(
                event: SocketEvent.unspecified,
                data: Message(msg: "Socket Added", recipient: 'TEST')));
          }
          //_startHeartBeatTimer();
          _listenToMessage();
          /*while (_sendBuffer.isNotEmpty) {
            String text = _sendBuffer.first;
            _sendBuffer.remove(text);
            _push(text);
          }*/
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

  void subscribe(SocketEntry entry) {
    _push(entry.toJsonString());
  }

  _startHeartBeatTimer() {
    _heartBeatTimer?.cancel();
    _heartBeatTimer =
        Timer.periodic(Duration(seconds: _heartbeatInterval), (Timer timer) {
      _client?.sink.add("${timer.tick}");
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

  int _fromByTESToInt32(List<int> elements) {
    ByteBuffer buffer = Int8List.fromList(elements).buffer;
    ByteData byteData = ByteData.view(buffer);
    return byteData.getInt32(0);
  }

  int _fromByTESToInt64(List<int> elements) {
    ByteBuffer buffer = Int8List.fromList(elements).buffer;
    ByteData byteData = ByteData.view(buffer);
    return byteData.getInt64(0);
  }

  @override
  void onData(message) {
    try {
      Map<String, dynamic> map = getJsonFromString(message);
      debugPrint("converted $map ${map['data'].toString()}");
      var entry = SocketEntry(event: SocketEvent.from(map[Serializable.event]));
      switch (entry.event) {
        case SocketEvent.unspecified:
          var message = Message.fromJson(map[Serializable.data]);
          WsEvent.addMessage?.call(message);
          break;
        case SocketEvent.add:
          var message = Message.fromJson(jsonDecode(map[Serializable.data]));
          WsEvent.addMessage?.call(message);
          break;
      }
    } on FormatException catch (ex) {
      debugPrint("ex1 ${ex.message} $ex");
      /*_push(SocketEntry(
              event: SocketEvent.error,
              data: Message(msg: ex.message, recipient: 'TEST'))
          .toJsonString());*/
    } on Exception catch (ex, s) {
      debugPrint("ex2 ${s}");
      /*_push(SocketEntry(
              event: SocketEvent.error,
              data: Message(msg: s.toString(), recipient: 'TEST'))
          .toJsonString());*/
    }
  }
}
