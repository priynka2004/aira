enum MediaTypeEnum {
  image,
  video;

  String toJson() => name;
  static MediaTypeEnum fromJson(String json) => values.byName(json);
}
