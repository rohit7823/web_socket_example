abstract class Serializable {
  Map<String, dynamic> toJson();

  static const String event = 'event';
  static const String data = 'data';
}
