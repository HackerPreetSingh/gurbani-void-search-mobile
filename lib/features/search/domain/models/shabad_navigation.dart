class ShabadNavigation {
  final String? previousId;
  final String? nextId;

  const ShabadNavigation({this.previousId, this.nextId});

  bool get hasPrevious => previousId != null;
  bool get hasNext => nextId != null;
}
