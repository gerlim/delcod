class AdminUserCreateRequest {
  const AdminUserCreateRequest({
    required this.matricula,
    required this.nome,
    required this.memberships,
    this.globalRole,
  });

  final String matricula;
  final String nome;
  final List<CompanyRoleAssignment> memberships;
  final String? globalRole;

  Map<String, Object?> toJson() {
    return {
      'matricula': matricula,
      'nome': nome,
      'memberships':
          memberships.map((item) => item.toJson()).toList(growable: false),
      'global_role': globalRole,
    };
  }
}

class CompanyRoleAssignment {
  const CompanyRoleAssignment({
    required this.companyId,
    required this.role,
  });

  final String companyId;
  final String role;

  Map<String, String> toJson() {
    return {
      'company_id': companyId,
      'role': role,
    };
  }
}
