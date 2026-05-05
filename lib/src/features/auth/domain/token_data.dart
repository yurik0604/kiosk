class TokenData {
  const TokenData({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      accessToken: (json['access'] ?? json['token']) as String? ?? '',
      refreshToken: json['refresh'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'access': accessToken,
        'refresh': refreshToken,
      };

  bool get isEmpty => accessToken.isEmpty;
}
