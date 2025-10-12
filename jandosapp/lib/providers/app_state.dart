import 'package:flutter/material.dart';
import '../models/checklist.dart';
import '../models/user_role.dart';

class AppState extends ChangeNotifier {
  UserRole? _role;
  String? _userName;
  String? _userEmail;
  final List<Checklist> _checklists = [];

  UserRole? get role => _role;
  String get userName => _userName ?? 'Usuário';
  String get userEmail => _userEmail ?? '';
  List<Checklist> get checklists => List.unmodifiable(_checklists);

  void signIn({required String name, required String email, required UserRole role}) {
    _userName = name;
    _userEmail = email;
    _role = role;
    notifyListeners();
  }

  void signOut() {
    _role = null;
    _userName = null;
    _userEmail = null;
    _checklists.clear();
    notifyListeners();
  }

  void addChecklist(Checklist c) {
    _checklists.insert(0, c);
    notifyListeners();
  }

  void removeChecklist(Checklist c) {
    _checklists.remove(c);
    notifyListeners();
  }

  void updateChecklist(Checklist oldC, Checklist newC) {
    final index = _checklists.indexOf(oldC);
    if (index != -1) {
      _checklists[index] = newC;
      notifyListeners();
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    Key? key,
    required AppState notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}