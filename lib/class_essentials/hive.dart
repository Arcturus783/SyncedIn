import 'package:hive_flutter/hive_flutter.dart';

//this class manages our library storing data like course names and IDs
class HiveBoxManager {
  static final HiveBoxManager _instance = HiveBoxManager._internal();
  late final Box<dynamic> box;
  bool _initialized = false;

  factory HiveBoxManager() {
    return _instance;
  }

  HiveBoxManager._internal();

  Future<void> init() async {
    if (!_initialized) {
      await Hive.initFlutter();
      box = await Hive.openBox("userData");
      _initialized = true;
    }
  }

  bool get isInitialized => _initialized;
}