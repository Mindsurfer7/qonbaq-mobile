import '../entities/entity.dart';

/// Вложение к согласованию
class ApprovalAttachment extends Entity {
  final String id;
  final String approvalId;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;

  const ApprovalAttachment({
    required this.id,
    required this.approvalId,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ApprovalAttachment(id: $id, fileName: $fileName)';
}

