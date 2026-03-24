import 'package:barcode_app/features/auth/application/auth_controller.dart';
import 'package:barcode_app/features/auth/domain/login_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef LoginSubmit = Future<void> Function(LoginRequest request);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    super.key,
    this.onSubmit,
  });

  final LoginSubmit? onSubmit;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _companyController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _matriculaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final request = LoginRequest(
      companyCode: _companyController.text.trim(),
      matricula: _matriculaController.text.trim(),
      password: _passwordController.text,
    );

    final submit = widget.onSubmit ?? ref.read(authControllerProvider.notifier).signIn;
    await submit(request);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode App')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Empresa'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _matriculaController,
              decoration: const InputDecoration(labelText: 'Matrícula'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
