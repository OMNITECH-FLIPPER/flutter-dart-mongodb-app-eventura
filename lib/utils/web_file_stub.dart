/// A stub implementation of the File class for web platforms
class WebFile {
  final String path;
  
  WebFile(this.path);
  
  Future<bool> exists() async {
    // For web, we'll just check if it's a web path
    return path.startsWith('web_');
  }
  
  Future<void> writeAsBytes(List<int> bytes) async {
    // For web, we'll just log it
    print('Web platform: Would write ${bytes.length} bytes to $path');
  }
  
  Future<void> delete() async {
    // For web, we'll just log it
    print('Web platform: Would delete file at $path');
  }
  
  Future<WebFileStat> stat() async {
    // For web, return mock stats
    return WebFileStat(1024, DateTime.now());
  }
}

/// A stub implementation of the FileStat class for web platforms
class WebFileStat {
  final int size;
  final DateTime modified;
  
  WebFileStat(this.size, this.modified);
}