import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/core/config.dart';
import 'package:hawacommand_app/core/prefs.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The field and community roles this app serves.
enum AppRole {
  driver(
    labelHi: 'ड्राइवर',
    labelEn: 'Driver · field team',
    descriptionHi: 'आज का रूट, छिड़काव अपने-आप दर्ज',
    descriptionEn: "Today's route, spray logged automatically",
    icon: LucideIcons.truck,
    homePath: '/driver',
  ),
  school(
    labelHi: 'स्कूल प्रिंसिपल',
    labelEn: 'School principal',
    descriptionHi: 'हवा की चेतावनी और सुरक्षित समय',
    descriptionEn: 'Air alerts and the safe outdoor window',
    icon: LucideIcons.school,
    homePath: '/school',
  ),
  citizen(
    labelHi: 'नागरिक',
    labelEn: 'Citizen Eyes',
    descriptionHi: 'धुआँ या कूड़ा जलता दिखे तो फ़ोटो भेजें',
    descriptionEn: 'Report burning with a photo',
    icon: LucideIcons.eye,
    homePath: '/citizen',
  );

  const AppRole({
    required this.labelHi,
    required this.labelEn,
    required this.descriptionHi,
    required this.descriptionEn,
    required this.icon,
    required this.homePath,
  });

  final String labelHi;
  final String labelEn;
  final String descriptionHi;
  final String descriptionEn;
  final IconData icon;
  final String homePath;

  static AppRole fromName(String? name) => AppRole.values.firstWhere(
    (r) => r.name == name,
    orElse: () => AppRole.driver,
  );
}

/// A signed-in demo user. The backend has no auth endpoints yet, so accounts
/// live only on this device (see Settings).
@immutable
class Session {
  const Session({
    required this.name,
    required this.phone,
    required this.role,
    this.assetId = AppConfig.defaultAssetId,
    this.orgName,
    this.isDemo = true,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    name: json['name'] as String? ?? 'Demo user',
    phone: json['phone'] as String? ?? '',
    role: AppRole.fromName(json['role'] as String?),
    assetId: json['assetId'] as String? ?? AppConfig.defaultAssetId,
    orgName: json['orgName'] as String?,
    isDemo: json['isDemo'] as bool? ?? true,
  );

  /// Ready-made accounts behind the "Demo login" button.
  factory Session.demoFor(AppRole role) => switch (role) {
    AppRole.driver => const Session(
      name: 'Ramesh Kumar',
      phone: '+91 98100 00012',
      role: AppRole.driver,
    ),
    AppRole.school => const Session(
      name: 'Sunita Sharma',
      phone: '+91 98100 00031',
      role: AppRole.school,
      orgName: 'Govt. Sarvodaya Vidyalaya',
    ),
    AppRole.citizen => const Session(
      name: 'Aman Verma',
      phone: '+91 98100 00047',
      role: AppRole.citizen,
    ),
  };

  final String name;
  final String phone;
  final AppRole role;
  final String assetId;
  final String? orgName;
  final bool isDemo;

  Session copyWith({AppRole? role}) => Session(
    name: name,
    phone: phone,
    role: role ?? this.role,
    assetId: assetId,
    orgName: orgName,
    isDemo: isDemo,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'role': role.name,
    'assetId': assetId,
    'orgName': orgName,
    'isDemo': isDemo,
  };
}

class SessionController extends Notifier<Session?> {
  @override
  Session? build() {
    final raw = ref.watch(sharedPrefsProvider).getString(PrefKeys.session);
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> signIn(Session session) async {
    await ref.read(sharedPrefsProvider).setString(PrefKeys.session, jsonEncode(session.toJson()));
    state = session;
  }

  /// Demo sign-up: remembers the account on this device and signs in.
  Future<void> signUp(Session session) async {
    final prefs = ref.read(sharedPrefsProvider);
    final accounts = (prefs.getStringList(PrefKeys.accounts) ?? <String>[])
      ..add(jsonEncode(session.toJson()));
    await prefs.setStringList(PrefKeys.accounts, accounts);
    await signIn(session);
  }

  Future<void> switchRole(AppRole role) async {
    final current = state;
    if (current == null) return;
    await signIn(current.copyWith(role: role));
  }

  Future<void> signOut() async {
    await ref.read(sharedPrefsProvider).remove(PrefKeys.session);
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);
