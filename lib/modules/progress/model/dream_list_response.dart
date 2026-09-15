
class DreamListResponse {
  final bool success;
  final String message;
  final List<DreamData> data;

  DreamListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DreamListResponse.fromJson(Map<String, dynamic> json) {
    return DreamListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: json['data'] != null
          ? List<DreamData>.from(
        (json['data'] as List).map((x) => DreamData.fromJson(x)),
      )
          : <DreamData>[],
    );
  }
}

class DreamData {
  final int id;
  final int dreamId;
  final String title;
  final String summary;
  final String image;
  final String createdAt;
  final bool isActive;
  final String emotion;
  final List<String> keywords;
  final String manifestationMessage;
  final bool isAnalyzed;

  // ✅ NEW FIELDS
  final String interpretation;
  final String guidance;
  final List<String> actionSteps;
  final List<DreamScene> scenes;

  /// True while the backend is still generating the dream images. The text is
  /// returned immediately; scenes/image fill in about a minute later.
  final bool imagesPending;
  // final int inputTokens;
  // final int outputTokens;

  // ✅ Chat history
  final List<MessageData> chatHistory;

  DreamData({
    required this.id,
    required this.dreamId,
    required this.title,
    required this.summary,
    required this.image,
    required this.createdAt,
    required this.isActive,
    required this.emotion,
    required this.keywords,
    required this.manifestationMessage,
    required this.isAnalyzed,
    required this.interpretation,
    required this.guidance,
    required this.actionSteps,
    required this.scenes,
    this.imagesPending = false,
    // required this.inputTokens,
    // required this.outputTokens,
    required this.chatHistory,
  });

  factory DreamData.fromJson(Map<String, dynamic> json) {
    return DreamData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      dreamId: (json['dream_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,

      // id: json['id'] ?? 0,
      // dreamId: json['dream_id'] ?? json['id'] ?? 0,
      title: json['title'] ?? "Untitled Dream",
      summary: json['summary'] ?? "",
      image: json['image'] ?? json['image_url'] ?? "",
      createdAt: json['created_at'] ?? "",
      isActive: json['is_active'] ?? true,
      emotion: json['emotion'] ?? "Neutral",
      keywords: json['keywords'] != null
          ? List<String>.from(
        json['keywords'].map((x) => x.toString()),
      )
          : <String>[],
      manifestationMessage: json['manifestation_message'] ?? "",
      isAnalyzed: json['is_analyzed'] ?? false,

      // ✅ NEW FIELD PARSING
      interpretation: json['interpretation'] ?? "",
      guidance: json['guidance'] ?? "",
      actionSteps: json['action_steps'] != null
          ? List<String>.from(
        json['action_steps'].map((x) => x.toString()),
      )
          : <String>[],
      scenes: json['scenes'] != null
          ? List<DreamScene>.from(
        (json['scenes'] as List)
            .map((x) => DreamScene.fromJson(x)),
      )
          : <DreamScene>[],
      imagesPending: json['images_pending'] ?? false,
      // inputTokens: json['input_tokens'] ?? 0,
      // outputTokens: json['output_tokens'] ?? 0,

      // ✅ Chat history
      chatHistory: json['messages'] != null
          ? List<MessageData>.from(
        (json['messages'] as List)
            .map((x) => MessageData.fromJson(x)),
      )
          : <MessageData>[],
    );
  }
}

class DreamScene {
  final String title;
  final String imageUrl;
  final int order;

  DreamScene({
    required this.title,
    required this.imageUrl,
    required this.order,
  });

  factory DreamScene.fromJson(Map<String, dynamic> json) {
    return DreamScene(
      title: json['title'] ?? "",
      imageUrl: json['image_url'] ?? "",
      order: json['order'] ?? 0,
    );
  }
}

class MessageData {
  final int id;
  final String role;
  final String content;

  MessageData({
    required this.id,
    required this.role,
    required this.content,
  });

  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      id: json['id'] ?? 0,
      role: json['role'] ?? "user",
      content: json['content'] ?? "",
    );
  }
}