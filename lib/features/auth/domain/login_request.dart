class LoginRequest {
  const LoginRequest({
    required this.companyCode,
    required this.matricula,
    required this.password,
  });

  final String companyCode;
  final String matricula;
  final String password;
}
