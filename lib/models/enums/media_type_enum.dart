// FILE: models/enums/media_type_enum.dart  |  MODEL
// Enum: portfolio media type (image / video).

/// Enum: Media Type Enum values.
enum MediaTypeEnum {
  image,
  video;

  String toJson() => name;
  static MediaTypeEnum fromJson(String json) => values.byName(json);
}
