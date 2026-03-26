import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/features/admin/application/admin_controller.dart';
import 'package:barcode_app/features/admin/domain/admin_user_create_request.dart';
import 'package:barcode_app/features/companies/domain/fixed_companies.dart';
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
  final _senhaInicialController = TextEditingController();
  String? _cargoGlobal;
  late final Map<String, bool> _selectedCompanies;
  late final Map<String, String> _companyRoles;

  @override
  void initState() {
    super.initState();
    _selectedCompanies = {
      for (final company in fixedCompanies) company.code: false,
    };
    _companyRoles = {
      for (final company in fixedCompanies) company.code: 'reader',
    };
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    _senhaInicialController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final memberships = <CompanyRoleAssignment>[
      for (final company in fixedCompanies)
        if (_selectedCompanies[company.code] ?? false)
          CompanyRoleAssignment(
            companyCode: company.code,
            role: _companyRoles[company.code] ?? 'reader',
          ),
    ];

    final request = AdminUserCreateRequest(
      matricula: _matriculaController.text.trim(),
      nome: _nomeController.text.trim(),
      senhaInicial: _senhaInicialController.text,
      memberships: memberships,
      globalRole: _cargoGlobal,
    );

    await ref.read(adminControllerProvider.notifier).createUser(request);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario criado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreateUsers = ref.watch(adminControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Administracao',
          subtitle:
              'Crie usuarios, defina senhas iniciais e distribua acessos por empresa fixa.',
        ),
        const SizedBox(height: 20),
        Expanded(
          child: canCreateUsers
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1040;
                    final columnWidth = wide
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: columnWidth,
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dados do usuario',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 16),
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
                                      labelText: 'Matricula',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _senhaInicialController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Senha inicial',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: columnWidth,
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Privilegios e empresas',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String?>(
                                    value: _cargoGlobal,
                                    decoration: const InputDecoration(
                                      labelText: 'Cargo global',
                                    ),
                                    items: const [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Nenhum'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'gestor_global',
                                        child: Text('Gestor global'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'admin_global',
                                        child: Text('Admin global'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _cargoGlobal = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  for (final company in fixedCompanies) ...[
                                    CheckboxListTile(
                                      value: _selectedCompanies[company.code] ??
                                          false,
                                      title: Text(company.name),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCompanies[company.code] =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                    if (_selectedCompanies[company.code] ??
                                        false)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: _companyRoles[company.code],
                                          decoration: const InputDecoration(
                                            labelText: 'Papel',
                                          ),
                                          items: const [
                                            DropdownMenuItem<String>(
                                              value: 'reader',
                                              child: Text('Leitor'),
                                            ),
                                            DropdownMenuItem<String>(
                                              value: 'operator',
                                              child: Text('Operador'),
                                            ),
                                            DropdownMenuItem<String>(
                                              value: 'manager',
                                              child: Text('Gestor'),
                                            ),
                                            DropdownMenuItem<String>(
                                              value: 'admin',
                                              child: Text('Admin'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) {
                                              return;
                                            }

                                            setState(() {
                                              _companyRoles[company.code] =
                                                  value;
                                            });
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Criar usuario'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text('Acesso negado'),
                ),
        ),
      ],
    );
  }
}
