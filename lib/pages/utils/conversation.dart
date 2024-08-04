class Message {
  final String id;
  final String text;
  final String sender;
  final int timestamp;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      sender: json['sender'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp,
    };
  }
}

class Conversation {
  final String id;
  final String title;
  final String userId;
  final List<Message> messages;
  final int timestamp;

  Conversation({
    required this.id,
    required this.title,
    required this.userId,
    required this.messages,
    required this.timestamp,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var messagesFromJson = json['messages'] as List;
    List<Message> messageList =
        messagesFromJson.map((message) => Message.fromJson(message)).toList();

    return Conversation(
        id: json['id'],
        title: json['title'],
        userId: json['user_id'],
        messages: messageList,
        timestamp: json['timestamp']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'user_id': userId,
      'messages': messages.map((message) => message.toJson()).toList(),
      'timestamp': timestamp
    };
  }
}
