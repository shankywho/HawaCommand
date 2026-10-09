import 'package:hawa_app/core/storage/app_database.dart';

/// `AppDatabase(NativeDatabase.memory())`; close it in tearDown.
AppDatabase inMemoryDb() => AppDatabase.memory();
