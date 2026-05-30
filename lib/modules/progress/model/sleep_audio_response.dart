
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- DATA MODELS ---

class SleepAudioResponse {
  final bool success;
  final String message;
  final String dataType;
  final int sessionsCount;
  final String periodStart;
  final String periodEnd;
  final List<AudioCategoryData> data;

  SleepAudioResponse({
    required this.success,
    required this.message,
    required this.dataType,
    required this.sessionsCount,
    required this.periodStart,
    required this.periodEnd,
    required this.data,
  });

  factory SleepAudioResponse.fromJson(Map<String, dynamic> json) => SleepAudioResponse(
    success: json["success"] ?? false,
    message: json["message"] ?? "",
    dataType: json["data_type"] ?? "",
    sessionsCount: json["sessions_count"] ?? 0,
    periodStart: json["period_start"] ?? "",
    periodEnd: json["period_end"] ?? "",
    data: json["data"] == null
        ? []
        : List<AudioCategoryData>.from(json["data"].map((x) => AudioCategoryData.fromJson(x))),
  );
}

class AudioCategoryData {
  final String audioType;
  final String audioTypeLabel;
  final int count;
  final List<AudioItem> data;
  bool isExpanded; // Added for local UI tracking

  AudioCategoryData({
    required this.audioType,
    required this.audioTypeLabel,
    required this.count,
    required this.data,
    this.isExpanded = false,
  });

  factory AudioCategoryData.fromJson(Map<String, dynamic> json) => AudioCategoryData(
    audioType: json["audio_type"] ?? "",
    audioTypeLabel: json["audio_type_label"] ?? "",
    count: json["count"] ?? 0,
    data: json["data"] == null
        ? []
        : List<AudioItem>.from(json["data"].map((x) => AudioItem.fromJson(x))),
    isExpanded: false,
  );
}

class AudioItem {
  final int id;
  final String? audioFile;
  final int? durationSeconds;
  final DateTime? recordedAt;
  final String? recordedTime;
  final String? recordedDate;
  final String? description;
  final double? confidenceScore;
  final List<AnalysisPoint>? analysis;

  AudioItem({
    required this.id,
    this.audioFile,
    this.durationSeconds,
    this.recordedAt,
    this.recordedTime,
    this.recordedDate,
    this.description,
    this.confidenceScore,
    this.analysis,
  });

  factory AudioItem.fromJson(Map<String, dynamic> json) => AudioItem(
    id: json["id"],
    audioFile: json["audio_file"],
    durationSeconds: json["duration_seconds"],
    recordedAt: json["recorded_at"] == null ? null : DateTime.parse(json["recorded_at"]),
    recordedTime: json["recorded_time"],
    recordedDate: json["recorded_date"],
    description: json["description"],
    confidenceScore: (json["confidence_score"] as num?)?.toDouble(),
    analysis: json["analysis"] == null
        ? null
        : List<AnalysisPoint>.from(json["analysis"].map((x) => AnalysisPoint.fromJson(x))),
  );
}

class AnalysisPoint {
  final String label;
  final double score;

  AnalysisPoint({required this.label, required this.score});

  factory AnalysisPoint.fromJson(Map<String, dynamic> json) => AnalysisPoint(
    label: json["label"] ?? "",
    score: (json["score"] as num?)?.toDouble() ?? 0.0,
  );
}

class RecordingCategory {
  final String title;
  final String label; // 🔥 Add this
  final String emoji;
  final Color bgColor;
  final List<AudioItem> recordings;
  bool isExpanded;

  RecordingCategory({
    required this.title,
    required this.label, // 🔥 Add this
    required this.emoji,
    required this.bgColor,
    required this.recordings,
    this.isExpanded = false,
  });
}