import 'package:web_socket_example/serializable.dart';

class Message extends Serializable {
  final String msg;
  final String recipient;

  Message({required this.msg, required this.recipient});

  @override
  Map<String, dynamic> toJson() => {'msg': msg, 'recipient': recipient};

  factory Message.fromJson(Map<String, dynamic> json) => Message(
      msg: json['msg'] ?? "NULL", recipient: json['recipient'] ?? "NULL");
}
