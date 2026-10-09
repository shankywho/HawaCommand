/// RFC 9457 problem+json (backend API.md §1.4).
class ProblemDetails {
  const ProblemDetails({
    required this.status,
    this.type,
    this.title,
    this.detail,
    this.instance,
    this.rawCode,
    this.requestId,
    this.errors = const [],
    this.extra = const {},
  });

  factory ProblemDetails.fromJson(Map<String, Object?> json, {int? fallbackStatus}) {
    final errors = <FieldError>[];
    final rawErrors = json['errors'];
    if (rawErrors is List) {
      for (final e in rawErrors) {
        if (e is Map) {
          errors.add(
            FieldError(
              pointer: e['pointer']?.toString() ?? '',
              code: e['code']?.toString() ?? '',
              detail: e['detail']?.toString(),
            ),
          );
        }
      }
    }
    const known = {'type', 'title', 'status', 'detail', 'instance', 'code', 'request_id', 'errors'};
    return ProblemDetails(
      status: (json['status'] as num?)?.toInt() ?? fallbackStatus ?? 0,
      type: json['type'] as String?,
      title: json['title'] as String?,
      detail: json['detail'] as String?,
      instance: json['instance'] as String?,
      rawCode: json['code'] as String?,
      requestId: json['request_id'] as String?,
      errors: errors,
      extra: {
        for (final entry in json.entries)
          if (!known.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  final int status;
  final String? type;
  final String? title;
  final String? detail;
  final String? instance;

  /// The server's `code` as sent (API.md uses dotted codes such as `auth.otp_invalid`).
  final String? rawCode;
  final String? requestId;
  final List<FieldError> errors;
  final Map<String, Object?> extra;

  /// Stable code the app branches on. API.md §1.5 spells codes with a dotted prefix
  /// (`auth.otp_invalid`, `task.invalid_transition`); CONTRACTS §13.2 lists the app-branching
  /// codes without it (`otp_invalid`, `task_already_done`). Both spellings map to one value.
  String? get code => normalizeCode(rawCode ?? _codeFromType(type));

  static String? normalizeCode(String? code) {
    if (code == null || code.isEmpty) return null;
    const aliases = {
      'auth.otp_invalid': 'otp_invalid',
      'auth.otp_expired': 'otp_expired',
      'auth.otp_attempts_exceeded': 'otp_attempts_exceeded',
      'auth.otp_resend_too_soon': 'otp_rate_limited',
      'idempotency.in_progress': 'idempotency_in_progress',
      'idempotency.key_reuse_mismatch': 'idempotency_key_mismatch',
      'inspection.already_closed': 'inspection_already_closed',
      'upload.too_large': 'media_too_large',
    };
    return aliases[code] ?? code;
  }

  static String? _codeFromType(String? type) {
    const prefix = 'urn:hawa:problem:';
    if (type == null || !type.startsWith(prefix)) return null;
    return type.substring(prefix.length);
  }
}

class FieldError {
  const FieldError({required this.pointer, required this.code, this.detail});

  final String pointer;
  final String code;
  final String? detail;
}
