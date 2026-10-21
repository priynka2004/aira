// FILE: models/artist/create_portfolio.dart  |  MODEL
// Request data to upload a portfolio photo/video.
// Work samples (max 5, images only) are reviewed by admin and kept out of the public portfolio.

import 'package:image_picker/image_picker.dart';
import '../../models/enums/media_type_enum.dart';

/// Model: Create Portfolio.
class CreatePortfolio {
  final MediaTypeEnum mediaType;
  final int subCategoryId;
  final String? caption;
  final XFile file;
  final bool isWorkSample;

  CreatePortfolio({
    required this.mediaType,
    required this.subCategoryId,
    required this.file,
    this.caption,
    this.isWorkSample = false,
  });

  /// Converts this object to JSON for the API.
  Map<String, dynamic> toJson() => {
        'media_type': mediaType.name,
        'sub_category_id': subCategoryId,
        'caption': caption,
        'is_work_sample': isWorkSample,
      };
}
