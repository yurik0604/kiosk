/// Standard `{status, error, data}` envelope used by some backend endpoints
/// (e.g. the catalog download-url endpoint wraps its payload in `data`).
class ApiResponse<T> {
  final String status;
  final String? error;
  final T? data;

  const ApiResponse({
    required this.status,
    this.error,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] as String? ?? 'success',
      error: json['error'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  bool get isSuccess =>
      status.toLowerCase() == 'success' || status.toLowerCase() == 'ok';
  bool get hasError => error != null && error!.isNotEmpty;
}

/// DRF-style paginated response (`{next, previous, results}`). The group list
/// endpoint (`v1/groups/`) returns this shape.
class PaginatedApiResponse<T> {
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedApiResponse({
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedApiResponse<T>(
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>? ?? const [])
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;
  int get count => results.length;
}
