import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/checklist.dart';
import '../models/user_role.dart';

class AppState extends ChangeNotifier {
  UserRole? _role;
  String? _userName;
  String? _userEmail;
  String? _userUid;
  final List<Checklist> _checklists = [];

  UserRole? get role => _role;
  String get userName => _userName ?? 'Usuário';
  String get userEmail => _userEmail ?? '';
  String? get userUid => _userUid;
  List<Checklist> get checklists => List.unmodifiable(_checklists);

  final DatabaseReference database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _roleStream;
  StreamSubscription<DatabaseEvent>? _nameStream;
  StreamSubscription<DatabaseEvent>? _checklistsSub;

  /// 🔹 Inicializa o AppState com o usuário autenticado
  Future<void> signInWithFirebase(User user) async {
    _userEmail = user.email;
    _userUid = user.uid;

    debugPrint('🔐 Usuário logado: ${user.uid} (${user.email})');

    // 🔸 Escuta o papel do usuário
    _roleStream = database.child('users/${user.uid}/role').onValue.listen((event) {
      final roleStr = event.snapshot.value?.toString().toLowerCase() ?? 'mechanic';
      _role = (roleStr == 'admin') ? UserRole.admin : UserRole.mechanic;
      debugPrint('🧠 Papel detectado: $_role');
      notifyListeners();
    });

    // 🔸 Escuta o nome do usuário
    _nameStream = database.child('users/${user.uid}/name').onValue.listen((event) {
      _userName = event.snapshot.value?.toString() ?? user.email!.split('@')[0];
      debugPrint('👤 Nome detectado: $_userName');
      notifyListeners();
    });

    // 🔸 Escuta checklists em tempo real
    await _listenChecklists();
  }

  /// 🔄 Escuta os checklists em tempo real
  Future<void> _listenChecklists() async {
    await _checklistsSub?.cancel();

    _checklists.clear();
    notifyListeners();

    final ref = database.child('checklists').orderByChild('createdAt');
    debugPrint('📡 Escutando alterações em tempo real nos checklists...');

    _checklistsSub = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        _checklists.clear();
        notifyListeners();
        return;
      }

      final map = Map<String, dynamic>.from(data as Map);
      final list = <Checklist>[];

      for (final e in map.values) {
        final item = Checklist.fromMap(Map<String, dynamic>.from(e));
        // 🔒 Mecânico vê apenas seus próprios checklists
        if (_role == UserRole.mechanic && item.createdByUid != _userUid) continue;
        list.add(item);
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _checklists
        ..clear()
        ..addAll(list);
      notifyListeners();

      debugPrint('✅ Atualização em tempo real recebida (${list.length} checklists).');
    });
  }

  /// 🚪 Encerra sessão e cancela listeners
  Future<void> signOut() async {
    await _roleStream?.cancel();
    await _nameStream?.cancel();
    await _checklistsSub?.cancel();
    _roleStream = null;
    _nameStream = null;
    _checklistsSub = null;

    _role = null;
    _userName = null;
    _userEmail = null;
    _userUid = null;
    _checklists.clear();
    notifyListeners();

    debugPrint('🚪 Logout realizado e listeners encerrados.');
  }

  /// ➕ Adiciona novo checklist
  Future<void> addChecklist(Checklist c) async {
    _checklists.insert(0, c);
    notifyListeners();

    try {
      await database.child('checklists').child(c.id).set(c.toMap());
      debugPrint('✅ Checklist ${c.id} salvo no Firebase.');
    } catch (e, s) {
      debugPrint('❌ Erro ao salvar checklist: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  /// ❌ Remove checklist
  Future<void> removeChecklist(Checklist c) async {
    _checklists.removeWhere((x) => x.id == c.id);
    notifyListeners();

    try {
      await database.child('checklists').child(c.id).remove();
      debugPrint('🗑️ Checklist ${c.id} removido.');
    } catch (e) {
      debugPrint('❌ Erro ao remover checklist: $e');
    }
  }

  /// ✏️ Atualiza checklist existente
  Future<void> updateChecklist(Checklist oldC, Checklist newC) async {
    try {
      final index = _checklists.indexWhere((c) => c.id == oldC.id);

      debugPrint('🧩 Chamando updateChecklist para ID: ${oldC.id}');
      if (index == -1) {
        debugPrint('⚠️ Checklist ${oldC.id} não encontrado localmente. Adicionando novo...');
        _checklists.insert(0, newC);
      } else {
        _checklists[index] = newC;
      }

      notifyListeners();

      await database.child('checklists').child(newC.id).set(newC.toMap());
      debugPrint('♻️ Checklist ${newC.id} atualizado no Firebase.');
    } catch (e, s) {
      debugPrint('❌ Erro ao atualizar checklist: $e');
      debugPrintStack(stackTrace: s);
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
    assert(scope != null, 'AppStateScope não encontrado no contexto');
    return scope!.notifier!;
  }
}
