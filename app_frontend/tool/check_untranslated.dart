import 'dart:convert';
import 'dart:io';

/// Fails when `flutter gen-l10n` reported untranslated Hindi messages (LINTING_AND_QUALITY §1).
void main() {
  final file = File('build/l10n_untranslated.json');
  if (!file.existsSync()) {
    stdout.writeln('no untranslated report (run flutter gen-l10n first)');
    return;
  }
  final report = jsonDecode(file.readAsStringSync());
  if (report is Map && report.isNotEmpty) {
    stderr.writeln('Untranslated messages: ${jsonEncode(report)}');
    exitCode = 1;
    return;
  }
  stdout.writeln('all messages translated');
}
