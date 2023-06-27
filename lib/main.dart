import 'package:flutter/material.dart';
import 'package:web_socket_example/web_socket_client.dart';

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
  late final WebSocketClient client = WebSocketClient.getInstance();
  List<String> _messages = [];

  @override
  void initState() {
    WebSocketClient.onData = (message) {
      setState(() {
        _messages.add(message);
      });
    };

    super.initState();
    client.connectToSocket();
    client.isSocketConnected;
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty) {
      debugPrint("trying $message");
      client.subscribe(message);
    }
    _textEditingController.clear();
  }

  @override
  void dispose() {
    client.disconnect();
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
