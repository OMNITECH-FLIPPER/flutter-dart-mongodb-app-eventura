class File {
  final String path;
  File(this.path);

  Future<bool> exists() async {
    return false;
  }

  Future<void> writeAsBytes(List<int> bytes) async {}

  Future<void> delete() async {}

  Future<FileStat> stat() async {
    return FileStat(0, DateTime.now());
  }
}

class FileStat {
  final int size;
  final DateTime modified;

  FileStat(this.size, this.modified);
}