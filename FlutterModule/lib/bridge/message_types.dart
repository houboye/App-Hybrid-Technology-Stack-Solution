class EventMessage {
  final String id;
  final String type;
  final String channel;
  final String source;
  final String target;
  final Map<String, dynamic> payload;
  final String? callbackId;
  final int timestamp;

  EventMessage({
    required this.id,
    required this.type,
    required this.channel,
    required this.source,
    required this.target,
    this.payload = const {},
    this.callbackId,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory EventMessage.fromJson(Map<String, dynamic> json) {
    return EventMessage(
      id: json['id'] as String,
      type: json['type'] as String,
      channel: json['channel'] as String,
      source: json['source'] as String,
      target: json['target'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      callbackId: json['callbackId'] as String?,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'channel': channel,
      'source': source,
      'target': target,
      'payload': payload,
      'callbackId': callbackId,
      'timestamp': timestamp,
    };
  }
}
