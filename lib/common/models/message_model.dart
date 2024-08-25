import 'package:whatsapp_messenger/common/enum/message_type.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String textMessage;
  final MessageType type;
  final String? name;
  final DateTime timeSent;
  final String messageId;
  final bool isSeen;

  MessageModel({
    this.name,
    required this.senderId,
    required this.receiverId,
    required this.textMessage,
    required this.type,
    required this.timeSent,
    required this.messageId,
    required this.isSeen,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      name: map['name'] ?? '',
      senderId: map["senderId"],
      receiverId: map["receiverId"],
      textMessage: map["textMessage"],
      type: (map["type"] as String).toEnum(),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map["timeSent"]),
      messageId: map["messageId"],
      isSeen: map["isSeen"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "senderId": senderId,
      "receiverId": receiverId,
      "textMessage": textMessage,
      "type": type.type,
      "timeSent": timeSent.millisecondsSinceEpoch,
      "messageId": messageId,
      "isSeen": isSeen,
    };
  }
}