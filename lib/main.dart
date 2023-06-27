import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  late final WebSocketChannel channel;
  List<String> _messages = [];

  Future<bool> checkStatus() async {
    var isCompleted = false;

    await channel.ready;
    isCompleted = true;

    return isCompleted;
  }

  @override
  void initState() {
    super.initState();
    try {
      channel = IOWebSocketChannel.connect(
          Uri.parse('ws://192.168.29.235:3000/TEST'));
    } on WebSocketChannelException catch (ex) {
      debugPrint("exception ${ex.message}");
    } on Exception catch (ex) {
      debugPrint("exception $ex");
    }

    channel.stream.listen((message) {
      setState(() {
        _messages.add(message);
      });
    }, onError: (data) {}, onDone: () {}, cancelOnError: false);
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty) {
      channel.sink.add({"fromClient": message}.toString());
    }
    _textEditingController.clear();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, index) => ListTile(
                title: Text(_messages[index]),
              ),
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: TextField(
                      controller: _textEditingController,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Send a message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage(_textEditingController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
