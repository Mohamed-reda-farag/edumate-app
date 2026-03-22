
int stableHash(String input) {
  var hash = 5381;
  for (final codeUnit in input.codeUnits) {
    // djb2: hash = hash * 33 ^ char
    hash = ((hash << 5) + hash) ^ codeUnit;
  }
  // نضمن القيمة الموجبة عبر تحويل لـ unsigned 32-bit
  return hash & 0x7FFFFFFF;
}