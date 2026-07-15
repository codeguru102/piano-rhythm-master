import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web: back sqflite with the WASM SQLite build (IndexedDB-persisted).
/// Requires the assets copied by `dart run sqflite_common_ffi_web:setup`.
Future<void> initDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}
