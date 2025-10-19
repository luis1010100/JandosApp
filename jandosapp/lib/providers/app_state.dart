import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

  final DatabaseReference database = FirebaseDatabase.instance.ref();
  Stream<DatabaseEvent>? _roleStream;
  Stream<DatabaseEvent>? _nameStream;

  /// Inicia AppState com dados do usuário logado
  Future<void> signInWithFirebase(User user) async {
    _userEmail = user.email;

    // Role stream único
    _roleStream ??= database.child('users/${user.uid}/role').onValue;
    _roleStream!.listen((event) {
      final roleStr = event.snapshot.value?.toString().toLowerCase() ?? 'mechanic';
      _role = roleStr == 'admin' ? UserRole.admin : UserRole.mechanic;
      notifyListeners();
    });

    // Name stream único
    _nameStream ??= database.child('users/${user.uid}/name').onValue;
    _nameStream!.listen((event) {
      _userName = event.snapshot.value?.toString() ?? user.email!.split('@')[0];
      notifyListeners();
    });

    // Carrega checklists do Firebase
    await loadChecklists();
  }

  Future<void> loadChecklists() async {
    final snapshot = await database.child('checklists').get();
    if (snapshot.exists) {
      _checklists.clear();
      for (var child in snapshot.children) {
        final checklist = Checklist.fromMap(Map<String, dynamic>.from(child.value as Map));
        _checklists.add(checklist);
      }
      notifyListeners();
    }
  }

  void signOut() {
    _role = null;
    _userName = null;
    _userEmail = null;
    _checklists.clear();
    notifyListeners();
  }

  Future<void> addChecklist(Checklist c) async {
    _checklists.insert(0, c);
    notifyListeners();
    await database.child('checklists').child(c.id).set(c.toMap());
  }

  void removeChecklist(Checklist c) {
    _checklists.remove(c);
    notifyListeners();
    database.child('checklists').child(c.id).remove();
  }

  void updateChecklist(Checklist oldC, Checklist newC) {
    final index = _checklists.indexOf(oldC);
    if (index != -1) {
      _checklists[index] = newC;
      notifyListeners();
      database.child('checklists').child(newC.id).set(newC.toMap());
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}
