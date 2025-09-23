const String tagSeparatorPattern = r'[、,]';

final RegExp tagSeparatorRegExp = RegExp(tagSeparatorPattern);

List<String> parseTags(String raw) {
  return raw
      .split(tagSeparatorRegExp)
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
}
