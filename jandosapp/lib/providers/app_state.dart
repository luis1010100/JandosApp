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

  // ===============================================================
  // 🔐 LOGIN → Inicializa dados do usuário
  // ===============================================================
  Future<void> signInWithFirebase(User user) async {
    _userEmail = user.email;
    _userUid = user.uid;

    debugPrint('🔐 Usuário logado: ${user.uid} (${user.email})');

    // Escuta papel (admin / mecânico)
    _roleStream = database.child('users/${user.uid}/role').onValue.listen((
      event,
    ) {
      final roleStr = (event.snapshot.value?.toString() ?? 'mechanic')
          .toLowerCase();
      _role = roleStr == 'admin' ? UserRole.admin : UserRole.mechanic;
      notifyListeners();
    });

    // Escuta nome do usuário
    _nameStream = database.child('users/${user.uid}/name').onValue.listen((
      event,
    ) {
      _userName = event.snapshot.value?.toString() ?? user.email!.split('@')[0];
      notifyListeners();
    });

    // Escuta checklists
    await _listenChecklists();
  }

  // ===============================================================
  // 🔄 Escuta checklists em tempo real
  // ===============================================================
  Future<void> _listenChecklists() async {
    await _checklistsSub?.cancel();

    _checklists.clear();
    notifyListeners();

    final ref = database.child('checklists').orderByChild('createdAt');

    _checklistsSub = ref.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data == null) {
        _checklists.clear();
        notifyListeners();
        return;
      }

      final map = Map<String, dynamic>.from(data as Map);
      final list = <Checklist>[];

      for (final raw in map.values) {
        final item = Checklist.fromMap(Map<String, dynamic>.from(raw));

        // mecânico só vê o que ele criou
        if (_role == UserRole.mechanic && item.createdByUid != _userUid) {
          continue;
        }

        list.add(item);
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _checklists
        ..clear()
        ..addAll(list);

      notifyListeners();
    });
  }

  // ===============================================================
  // 🚪 LOGOUT
  // ===============================================================
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
  }

  // ===============================================================
  // ➕ Adicionar checklist
  // ===============================================================
  Future<void> addChecklist(Checklist c) async {
    _checklists.insert(0, c);
    notifyListeners();

    try {
      await database.child('checklists').child(c.id).set(c.toMap());
    } catch (e) {
      debugPrint('❌ Erro ao adicionar checklist: $e');
    }
  }

  // ===============================================================
  // ❌ Remover checklist
  // ===============================================================
  Future<void> removeChecklist(Checklist c) async {
    _checklists.removeWhere((x) => x.id == c.id);
    notifyListeners();

    try {
      await database.child('checklists').child(c.id).remove();
    } catch (e) {
      debugPrint('❌ Erro ao remover checklist: $e');
    }
  }

  // ===============================================================
  // ✏️ Atualizar checklist completo
  // ===============================================================
  Future<void> updateChecklist(Checklist oldC, Checklist newC) async {
    try {
      final index = _checklists.indexWhere((c) => c.id == oldC.id);

      if (index == -1) {
        _checklists.add(newC);
      } else {
        _checklists[index] = newC;
      }

      notifyListeners();

      await database.child('checklists').child(newC.id).set(newC.toMap());
    } catch (e) {
      debugPrint('❌ Erro ao atualizar checklist: $e');
    }
  }

  // ===============================================================
  // 💰 NOVO! — Salvar orçamento prévio
  // ===============================================================
  Future<void> addOrcamentoPrevio(Checklist updated) async {
    try {
      final index = _checklists.indexWhere((c) => c.id == updated.id);

      if (index != -1) {
        _checklists[index] = updated;
        notifyListeners();
      }

      await database.child('checklists').child(updated.id).update({
        'orcamentoPrevio': updated.orcamentoPrevio,
        'orcamentoAutor': updated.orcamentoAutor,
        'orcamentoData': updated.orcamentoData?.toIso8601String(),
      });

      debugPrint('💰 Orçamento salvo no checklist ${updated.id}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar orçamento: $e');
    }
  }
}

// =====================================================================
// 🔗 Bridge para acessar AppState em qualquer Widget
// =====================================================================
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(s != null, 'AppStateScope não encontrado no contexto');
    return s!.notifier!;
  }
}
