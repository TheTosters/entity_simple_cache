class CacheEntry<T> {
  DateTime validUntil;
  T value;

  CacheEntry({
    required this.validUntil,
    required this.value,
  });
}
