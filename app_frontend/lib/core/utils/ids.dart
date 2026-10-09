import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// New UUIDv7: client op ids (also the `Idempotency-Key`), request ids, client report ids.
String newId() => _uuid.v7();

final _uuidV7 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
final _schoolId = RegExp(r'^SCH-[0-9A-Za-z]+$');
final _siteId = RegExp(r'^SITE-\d{4}$');

bool isUuidV7(String value) => _uuidV7.hasMatch(value.toLowerCase());

/// Id formats from CONTRACTS §2 accepted in deep links.
bool isSchoolId(String value) => _schoolId.hasMatch(value);

bool isSiteId(String value) => _siteId.hasMatch(value);
