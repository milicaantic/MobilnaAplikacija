
enum UserRole {
  guest,
  user,
  admin;

  bool get canCreateEvents => this == user || this == admin;

  bool get isAdmin => this == admin;
}
