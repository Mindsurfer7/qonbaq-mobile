import '../../domain/entities/approval_attachment.dart';
import '../models/model.dart';

/// Модель вложения к согласованию
class ApprovalAttachmentModel extends ApprovalAttachment implements Model {
  const ApprovalAttachmentModel({
    required super.id,
    required super.approvalId,
    required super.fileUrl,
    super.fileName,
    super.fileType,
    super.fileSize,
    required super.createdAt,
  });

  factory ApprovalAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ApprovalAttachmentModel(
      id: json['id'] as String,
      approvalId: json['approvalId'] as String,
      fileUrl: json['fileUrl'] as String,
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
      fileSize: json['fileSize'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'approvalId': approvalId,
      'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ApprovalAttachment toEntity() {
    return ApprovalAttachment(
      id: id,
      approvalId: approvalId,
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      createdAt: createdAt,
    );
  }

  factory ApprovalAttachmentModel.fromEntity(ApprovalAttachment attachment) {
    return ApprovalAttachmentModel(
      id: attachment.id,
      approvalId: attachment.approvalId,
      fileUrl: attachment.fileUrl,
      fileName: attachment.fileName,
      fileType: attachment.fileType,
      fileSize: attachment.fileSize,
      createdAt: attachment.createdAt,
    );
  }
}

