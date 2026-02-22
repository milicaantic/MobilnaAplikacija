/// Defines the access roles for the application.
///
/// - [guest]: Can only view approved events, search, and filter.
/// - [user]: Can register for events, comment, rate, and manage own events.
/// - [admin]: Full access — can manage all events, categories, and comments.
enum UserRole {
  guest,
  user,
  admin;

  /// Whether this role can create/edit their own events.
  bool get canCreateEvents => this == user || this == admin;

  /// Whether this role has full admin privileges.
  bool get isAdmin => this == admin;
}
