import 'package:barcode_app/data/remote/supabase/supabase_client_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/auth/domain/login_request.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRemoteDataSource(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  return AuthRepository(remote);
});

class AuthRepository {
  AuthRepository(this._remote);
  AuthRepository.forTest() : _remote = const _NoopAuthRemoteDataSource();

  final AuthRemoteDataSource _remote;

  Future<CurrentSession?> loadCurrentSession() async {
    if (_remote.currentUserId == null) {
      return null;
    }

    return _hydrateSession();
  }

  Future<CurrentSession> signIn(LoginRequest request) async {
    final technicalEmail = '${request.matricula}@local.barcode-app';

    await _remote.signInWithPassword(
      email: technicalEmail,
      password: request.password,
    );

    try {
      return await _hydrateSession(
        preferredCompanyCode: request.companyCode,
        updateLastLogin: true,
      );
    } catch (_) {
      await _remote.signOut();
      rethrow;
    }
  }

  Future<CurrentSession> _hydrateSession({
    String? preferredCompanyCode,
    bool updateLastLogin = false,
  }) async {
    final userId = _remote.currentUserId;
    if (userId == null) {
      throw StateError('Sessao do usuario nao encontrada.');
    }

    final profile = await _remote.fetchProfile(userId);
    if (profile == null || profile.status != 'active') {
      throw StateError('Perfil do usuario nao esta ativo.');
    }

    final companies = await _remote.fetchAccessibleCompanies(
      userId: userId,
      globalRole: profile.globalRole,
    );

    String? activeCompanyId;
    if (preferredCompanyCode case final String companyCode?) {
      for (final company in companies) {
        if (company.companyCode == companyCode) {
          activeCompanyId = company.companyId;
          break;
        }
      }

      if (activeCompanyId == null) {
        throw StateError('Usuario sem acesso a empresa selecionada.');
      }
    } else if (companies.length == 1) {
      activeCompanyId = companies.first.companyId;
    }

    if (updateLastLogin) {
      await _remote.updateLastLogin(userId);
    }

    return CurrentSession(
      userId: profile.userId,
      activeCompanyId: null,
      roles: const {},
      matricula: profile.matricula,
      nome: profile.nome,
      globalRole: profile.globalRole,
      availableCompanies: companies,
    ).withActiveCompany(activeCompanyId);
  }
}

class AuthProfile {
  const AuthProfile({
    required this.userId,
    required this.matricula,
    required this.nome,
    required this.status,
    this.globalRole,
  });

  final String userId;
  final String matricula;
  final String nome;
  final String status;
  final String? globalRole;
}

abstract class AuthRemoteDataSource {
  String? get currentUserId;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AuthProfile?> fetchProfile(String userId);

  Future<List<CompanyAccess>> fetchAccessibleCompanies({
    required String userId,
    required String? globalRole,
  });

  Future<void> updateLastLogin(String userId);
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  SupabaseAuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<AuthProfile?> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('id, matricula, nome, status, cargo_global')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AuthProfile(
      userId: response['id'] as String,
      matricula: response['matricula'] as String,
      nome: response['nome'] as String,
      status: response['status'] as String,
      globalRole: response['cargo_global'] as String?,
    );
  }

  @override
  Future<List<CompanyAccess>> fetchAccessibleCompanies({
    required String userId,
    required String? globalRole,
  }) async {
    if (globalRole == 'admin_global' || globalRole == 'gestor_global') {
      final response = await _client
          .from('companies')
          .select('id, code, name')
          .eq('status', 'active')
          .order('name');

      final inheritedRole = globalRole == 'admin_global' ? 'admin' : 'manager';
      return response
          .map<CompanyAccess>(
            (item) => CompanyAccess(
              companyId: item['id'] as String,
              companyCode: item['code'] as String,
              companyName: item['name'] as String,
              role: inheritedRole,
            ),
          )
          .toList(growable: false);
    }

    final response = await _client
        .from('company_memberships')
        .select('company_id, role, companies!inner(id, code, name, status)')
        .eq('user_id', userId)
        .eq('status', 'active');

    final companies = <CompanyAccess>[];
    for (final item in response) {
      final company = item['companies'];
      if (company is! Map<String, dynamic>) {
        continue;
      }

      if (company['status'] != 'active') {
        continue;
      }

      companies.add(
        CompanyAccess(
          companyId: item['company_id'] as String,
          companyCode: company['code'] as String,
          companyName: company['name'] as String,
          role: item['role'] as String,
        ),
      );
    }

    return companies;
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    await _client
        .from('profiles')
        .update({'ultimo_login': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  }
}

class _NoopAuthRemoteDataSource implements AuthRemoteDataSource {
  const _NoopAuthRemoteDataSource();

  @override
  String? get currentUserId => null;

  @override
  Future<List<CompanyAccess>> fetchAccessibleCompanies({
    required String userId,
    required String? globalRole,
  }) async {
    return const [];
  }

  @override
  Future<AuthProfile?> fetchProfile(String userId) async {
    return null;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateLastLogin(String userId) async {}
}
