class CurrentSession {
  const CurrentSession({
    required this.userId,
    required this.activeCompanyId,
    required this.roles,
  });

  final String userId;
  final String? activeCompanyId;
  final Set<String> roles;
}
