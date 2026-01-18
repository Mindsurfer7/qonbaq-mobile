/// Метаданные пагинации (доменный слой)
class PaginationMeta {
  final int? total;
  final int? page;
  final int? limit;
  final int? totalPages;

  const PaginationMeta({this.total, this.page, this.limit, this.totalPages});
}

/// Результат с пагинацией
class PaginatedResult<T> {
  final List<T> items;
  final PaginationMeta? meta;

  const PaginatedResult({required this.items, this.meta});
}
