import 'auth_user.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthStateData {
  const AuthStateData({
    required this.status,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  const AuthStateData.unknown() : this(status: AuthStatus.unknown);
  const AuthStateData.unauthenticated()
      : this(status: AuthStatus.unauthenticated);
  const AuthStateData.authenticating()
      : this(status: AuthStatus.authenticating);
  const AuthStateData.authenticated(AuthUser user)
      : this(status: AuthStatus.authenticated, user: user);
  const AuthStateData.error(String error)
      : this(status: AuthStatus.error, error: error);

  bool get isLoading => status == AuthStatus.authenticating;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isResolved => status != AuthStatus.unknown;

  AuthStateData copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
  }) =>
      AuthStateData(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );

  @override
  bool operator ==(Object other) =>
      other is AuthStateData &&
      other.status == status &&
      other.user == user &&
      other.error == error;

  @override
  int get hashCode => Object.hash(status, user, error);
}
