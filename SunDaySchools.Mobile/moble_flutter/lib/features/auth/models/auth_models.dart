class LoginDto {
  final String name;
  final String password;

  const LoginDto({required this.name, required this.password});

  Map<String, dynamic> toJson() => {'name': name, 'password': password};
}

class RegisterDto {
  final String name;
  final String phoneNumber;
  final String password;
  final String confirmPassword;

  const RegisterDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
  });
}
