class ChatRequest {
  final String question;
  final int? parentMessageId;

  ChatRequest({
    required this.question,
    this.parentMessageId,
  });

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      if (parentMessageId != null)
        "parent_message_id": parentMessageId,
    };
  }
}
