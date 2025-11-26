import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/user_role.dart';
import '../models/checklist.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  // 🎨 Paleta AutoCenter
  static const Color _primary = Color(0xFFCD193C);
  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _text = Color(0xFF1B1B1B);
  static const Color _subtext = Color(0xFF6B7280);

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.mechanic:
        return 'Mecânico';
      default:
        return '—';
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 2).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _metricTile(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: _primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _text,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 13, color: _subtext)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final name = app.userName;
    final email = app.userEmail.isEmpty ? 'sem e-mail' : app.userEmail;
    final role = app.role;

    final now = DateTime.now();
    final meusChecklists = app.checklists
        .where((c) => c.createdBy == app.userName)
        .toList();

    final checklistsMes = meusChecklists
        .where(
          (c) => c.createdAt.year == now.year && c.createdAt.month == now.month,
        )
        .length;

    final ultimoChecklist = meusChecklists.isNotEmpty
        ? (meusChecklists..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
              .first
        : null;

    final primeiroDoMes = meusChecklists
        .where(
          (c) => c.createdAt.year == now.year && c.createdAt.month == now.month,
        )
        .fold<Checklist?>(null, (prev, c) {
          if (prev == null || c.createdAt.isBefore(prev.createdAt)) return c;
          return prev;
        });

    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(color: _text, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              // ignore: deprecated_member_use
              backgroundColor: _primary.withOpacity(0.15),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            Text(
              email,
              style: const TextStyle(color: _subtext),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Chip(
              label: Text(_roleLabel(role)),
              avatar: Icon(
                role == UserRole.admin ? Icons.verified_user : Icons.build,
                size: 18,
                color: _primary,
              ),
              // ignore: deprecated_member_use
              backgroundColor: _primary.withOpacity(0.1),
            ),

            const SizedBox(height: 30),

            // CARD DE ATIVIDADE
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Atividade recente',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _metricTile(
                        Icons.assignment,
                        'Este mês',
                        '$checklistsMes',
                      ),
                      _metricTile(
                        Icons.bar_chart,
                        'Total',
                        '${meusChecklists.length}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _metricTile(
                        Icons.schedule,
                        'Último checklist',
                        ultimoChecklist != null
                            ? DateFormat(
                                'dd/MM',
                              ).format(ultimoChecklist.createdAt)
                            : '—',
                      ),
                      _metricTile(
                        Icons.calendar_today,
                        'Primeiro do mês',
                        primeiroDoMes != null
                            ? DateFormat(
                                'dd/MM',
                              ).format(primeiroDoMes.createdAt)
                            : '—',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // CARD DE DADOS
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Nome'),
                      subtitle: Text(name),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.alternate_email),
                      title: const Text('E-mail'),
                      subtitle: Text(email),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Função'),
                      subtitle: Text(_roleLabel(role)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
