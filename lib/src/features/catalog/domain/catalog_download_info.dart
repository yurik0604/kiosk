/// Presigned download details for the catalog file, returned by
/// `GET v1/groups/{id}/catalog/download-url/`.
class CatalogDownloadInfo {
  final String downloadUrl;
  final int fileSize;
  final String etag;

  const CatalogDownloadInfo({
    required this.downloadUrl,
    required this.fileSize,
    required this.etag,
  });

  factory CatalogDownloadInfo.fromJson(Map<String, dynamic> json) {
    return CatalogDownloadInfo(
      downloadUrl: json['download_url'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      etag: json['etag'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'CatalogDownloadInfo{fileSize: $fileSize, etag: $etag}';
}
