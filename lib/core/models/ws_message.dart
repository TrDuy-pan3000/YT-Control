import 'dart:convert';

enum WsType { command, event, sync }

class WsMessage {
  final WsType type;
  final String action;
  final Map<String, dynamic>? payload;

  const WsMessage({
    required this.type,
    required this.action,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name.toUpperCase(),
    'action': action,
    if (payload != null) 'payload': payload,
  };

  factory WsMessage.fromJson(Map<String, dynamic> json) => WsMessage(
    type: WsType.values.firstWhere(
      (e) => e.name.toUpperCase() == json['type'],
    ),
    action: json['action'] as String,
    payload: json['payload'] as Map<String, dynamic>?,
  );

  String encode() => jsonEncode(toJson());
  static WsMessage decode(String raw) => WsMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
