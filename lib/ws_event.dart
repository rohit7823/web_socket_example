import 'package:web_socket_example/message.dart';

class WsEvent {
  WsEvent._();
  static void Function(Message?)? addMessage;
}
