/// Mobile (Android/iOS): sqflite registers its default database factory
/// automatically, so nothing to do here. (Desktop would need
/// sqflite_common_ffi; not a target platform for this app.)
Future<void> initDatabaseFactory() async {}
