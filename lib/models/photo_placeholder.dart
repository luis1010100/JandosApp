class PhotoPlaceholder {
  final String path;

  PhotoPlaceholder(this.path);

  Map<String, dynamic> toMap() => {'path': path};

  factory PhotoPlaceholder.fromMap(Map<String, dynamic> map) {
    return PhotoPlaceholder(map['path'] as String);
  }
}
