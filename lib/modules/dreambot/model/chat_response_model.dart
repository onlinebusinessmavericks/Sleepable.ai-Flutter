class ChatResponse {
  final bool success;
  final ChatData? data;

  ChatResponse({
    required this.success,
    this.data,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? ChatData.fromJson(json['data'])
          : null,
    );
  }
}

class ChatData {
  final int parentMessageId;
  final String answer;

  ChatData({
    required this.parentMessageId,
    required this.answer,
  });

  factory ChatData.fromJson(Map<String, dynamic> json) {
    return ChatData(
      parentMessageId: json['parent_message_id'],
      answer: json['answer'],
    );
  }
}
