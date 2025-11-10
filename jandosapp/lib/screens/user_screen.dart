import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/user_role.dart';
import '../models/checklist.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

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
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 2).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _metricTile(IconData icon, String label, String value, BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final name = app.userName;
    final email = app.userEmail.isEmpty ? 'sem e-mail' : app.userEmail;
    final role = app.role;
    final theme = Theme.of(context);
    final now = DateTime.now();

    // === Dados de atividade ===
    final meusChecklists = app.checklists.where((c) => c.createdBy == app.userName).toList();

    final checklistsMes = meusChecklists
        .where((c) => c.createdAt.year == now.year && c.createdAt.month == now.month)
        .length;

    final ultimoChecklist = meusChecklists.isNotEmpty
        ? (meusChecklists..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first
        : null;

    final primeiroDoMes = meusChecklists
        .where((c) => c.createdAt.year == now.year && c.createdAt.month == now.month)
        .fold<Checklist?>(null, (prev, c) {
      if (prev == null || c.createdAt.isBefore(prev.createdAt)) return c;
      return prev;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ===== AVATAR + NOME =====
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Chip(
                label: Text(_roleLabel(role)),
                avatar: Icon(
                  role == UserRole.admin ? Icons.verified_user : Icons.build,
                  size: 18,
                ),
              ),

              const SizedBox(height: 30),

              // ===== CARD DE ATIVIDADE =====
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Atividade recente',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _metricTile(Icons.assignment, 'Este mês', '$checklistsMes', context),
                        _metricTile(Icons.bar_chart, 'Total', '${meusChecklists.length}', context),
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
                              ? DateFormat('dd/MM').format(ultimoChecklist.createdAt)
                              : '—',
                          context,
                        ),
                        _metricTile(
                          Icons.calendar_today,
                          'Primeiro do mês',
                          primeiroDoMes != null
                              ? DateFormat('dd/MM').format(primeiroDoMes.createdAt)
                              : '—',
                          context,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ===== CARD DE DADOS DO PERFIL =====
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Nome'),
                        subtitle: Text(name.isEmpty ? '—' : name),
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
      ),
    );
  }
}
