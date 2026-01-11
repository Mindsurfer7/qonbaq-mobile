import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/fixed_asset_repository.dart';

/// Параметры для добавления фото
class AddPhotoParams {
  final String id;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final bool? isInventoryPhoto;
  final String? inventoryId;

  AddPhotoParams({
    required this.id,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.isInventoryPhoto,
    this.inventoryId,
  });
}

/// Use Case для добавления фото
class AddPhoto implements UseCase<void, AddPhotoParams> {
  final FixedAssetRepository repository;

  AddPhoto(this.repository);

  @override
  Future<Either<Failure, void>> call(AddPhotoParams params) async {
    return await repository.addPhoto(
      params.id,
      fileUrl: params.fileUrl,
      fileName: params.fileName,
      fileType: params.fileType,
      isInventoryPhoto: params.isInventoryPhoto,
      inventoryId: params.inventoryId,
    );
  }
}
