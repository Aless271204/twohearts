import 'package:flutter/foundation.dart';

/// Simple app-wide notifier so screens can react when profile is updated
class ProfileChangeNotifier extends ChangeNotifier {
  static final ProfileChangeNotifier instance = ProfileChangeNotifier._();
  ProfileChangeNotifier._();

  void notify() => notifyListeners();
}
