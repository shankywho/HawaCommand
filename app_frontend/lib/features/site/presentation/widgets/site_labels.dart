import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/features/site/domain/site_score.dart';

extension SiteTypeLabel on SiteType {
  String label(AppLocalizations l) => switch (this) {
    SiteType.construction => l.siteTypeConstruction,
    SiteType.industrialUnit => l.siteTypeIndustrial,
    SiteType.wasteSite => l.siteTypeWaste,
    SiteType.other => l.siteTypeOther,
    SiteType.unknown => l.commonUnknown,
  };
}

/// "Grade B since 2 Nov" / "Grade B" / "Grade not available yet" (always with the letter).
String gradeLine(AppLocalizations l, SiteScore site, String lang) {
  final letter = site.grade.letter;
  if (letter == null) return l.siteGradeUnknown;
  final since = site.gradeSince;
  return since == null
      ? l.siteGradeLabel(letter)
      : l.siteGrade(letter, IstTime.dayMonth(since, lang));
}
