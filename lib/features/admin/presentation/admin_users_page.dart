import 'package:barcode_app/features/admin/application/admin_controller.dart';
import 'package:barcode_app/features/admin/domain/admin_user_create_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _nomeController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _empresasController = TextEditingController();
  final _papeisController = TextEditingController();
  final _cargoGlobalController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    _empresasController.dispose();
    _papeisController.dispose();
    _cargoGlobalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final request = AdminUserCreateRequest(
      matricula: _matriculaController.text.trim(),
      nome: _nomeController.text.trim(),
      memberships: _parseMemberships(
        companies: _empresasController.text,
        roles: _papeisController.text,
      ),
      globalRole: _cargoGlobalController.text.trim().isEmpty
          ? null
          : _cargoGlobalController.text.trim(),
    );

    await ref.read(adminControllerProvider.notifier).createUser(request);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário criado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreateUsers = ref.watch(adminControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
      ),
      body: canCreateUsers
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _matriculaController,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _empresasController,
                  decoration: const InputDecoration(
                    labelText: 'Empresas',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _papeisController,
                  decoration: const InputDecoration(
                    labelText: 'Papéis',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cargoGlobalController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo global',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Criar usuário'),
                ),
              ],
            )
          : const Center(
              child: Text('Acesso negado'),
            ),
    );
  }

  List<CompanyRoleAssignment> _parseMemberships({
    required String companies,
    required String roles,
  }) {
    final companyItems = companies
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final roleItems = roles
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return List<CompanyRoleAssignment>.generate(
      companyItems.length,
      (index) => CompanyRoleAssignment(
        companyId: companyItems[index],
        role: index < roleItems.length ? roleItems[index] : 'reader',
      ),
      growable: false,
    );
  }
}
