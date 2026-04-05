class AdminUserCreateRequest {
  const AdminUserCreateRequest({
    required this.matricula,
    required this.nome,
    required this.senhaInicial,
    required this.memberships,
    this.globalRole,
  });

  final String matricula;
  final String nome;
  final String senhaInicial;
  final List<CompanyRoleAssignment> memberships;
  final String? globalRole;

  Map<String, Object?> toJson() {
    return {
      'matricula': matricula,
      'nome': nome,
      'temporary_password': senhaInicial,
      'memberships':
          memberships.map((item) => item.toJson()).toList(growable: false),
      'global_role': globalRole,
    };
  }
}

class CompanyRoleAssignment {
  const CompanyRoleAssignment({
    required this.companyCode,
    required this.role,
  });

  final String companyCode;
  final String role;

  Map<String, String> toJson() {
    return {
      'company_code': companyCode,
      'role': role,
    };
  }
}

