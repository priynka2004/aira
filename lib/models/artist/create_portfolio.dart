import 'package:image_picker/image_picker.dart';
import '../../models/enums/media_type_enum.dart';

class CreatePortfolio {

  final MediaTypeEnum mediaType;
  final int subCategoryId;
  final String? caption;
  final XFile file;

  CreatePortfolio({
    required this.mediaType,
    required this.subCategoryId,
    required this.file,
    this.caption,
  });

  Map<String,dynamic> toJson(){

    return {
      "media_type": mediaType.name,
      "sub_category_id": subCategoryId,
      "caption": caption,
    };

  }

}
