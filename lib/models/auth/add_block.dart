class AddBlock {
  final String blockDate;
  final String? note;

  AddBlock({required this.blockDate, this.note});

  Map<String, dynamic> toJson() => {
    'block_date': blockDate,
    if (note != null) 'note': note,
  };
}
