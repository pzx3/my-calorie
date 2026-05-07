import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('.withOpacity(')) {
      content = content.replaceAllMapped(
        RegExp(r'\.withOpacity\(([^)]+)\)'),
        (match) => '.withValues(alpha: ${match.group(1)})',
      );
      file.writeAsStringSync(content);
      // ignore: avoid_print
      print('Updated ${file.path}');
    }
  }
}
