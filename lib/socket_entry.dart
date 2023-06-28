import 'dart:convert';

import 'package:web_socket_example/serializable.dart';

class SocketEntry<T extends Serializable> {
  SocketEvent event;
  T? data;

  SocketEntry({required this.event, this.data});

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() =>
      {Serializable.event: event.event, Serializable.data: data?.toJson()};

  factory SocketEntry.fromJson(SocketEvent action, T data) =>
      SocketEntry(event: action, data: data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocketEntry &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          data == other.data;

  @override
  int get hashCode => event.hashCode ^ data.hashCode;

  SocketEntry copyWith({
    SocketEvent? event,
    T? data,
  }) {
    return SocketEntry(
      event: event ?? this.event,
      data: data ?? this.data,
    );
  }
}

enum SocketEvent {
  unspecified("UNSPECIFIED"),
  error("ERROR"),
  add("ADD");

  final String event;

  const SocketEvent(this.event);

  static SocketEvent from(String json) =>
      SocketEvent.values.firstWhere((element) => element.event == json,
          orElse: () => SocketEvent.unspecified);

  static String to(SocketEvent? type) => type?.event ?? unspecified.event;
}
