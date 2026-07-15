import 'db_init_io.dart' if (dart.library.html) 'db_init_web.dart' as impl;

/// Configures the sqflite database factory for the current platform.
/// Must be called once before opening any database.
Future<void> initDatabaseFactory() => impl.initDatabaseFactory();
