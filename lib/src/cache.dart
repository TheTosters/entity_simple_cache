import 'dart:async';
import 'dart:collection';

import 'package:entity_simple_cache/src/cache_entry.dart';

///Simple cache for typed key and value. Class allows to configure few simple strategies to dispose
///expired entries:
///* Check whole cache for entries expiration after performing selected number of reads (set
///[revalidateHitCount] argument)
///* Check whole cache for entries expiration on demand (call method [removeExpired])
///* Use timer which will execute cache expiration check in periodic cycles
///(set [cleanupDuration] argument)
///Additionally you can constrain cache size by setting [maxLength], this will prevent cache for
///holding more then given entries. If cache is full and new item need to be added then:
///1. Check for expiration is done to get free space
///1. If no free space is obtained, naive search for oldest entries is executed. One entry will be
///removed and filled with new data
///
/// There are two methods to get cache size [length] returns approximate entries count (it might be
/// larger then actual available entries depending on expiration conditions). Call to [exactLength]
/// will return real entries count, however [removeExpired] is called internally to dispose expired
/// entries before counting it. If you need to check cache size prefer usage of [length] since it
/// is O[[1]] execution time.
class Cache<K, V> {
  final SplayTreeMap<K, CacheEntry<V>> _map = SplayTreeMap<K, CacheEntry<V>>();
  final Duration entriesExpiration;
  final int revalidateHitCount;
  final int maxLength;
  late final Timer? timer;

  K? _firstToRemove;
  int _hitCount = 0;
  int _count = 0;

  ///Arguments:
  ///* [entriesExpiration] determine after what time entry added to cache is considered as expired.
  ///It will be not possible to access it after this duration, however it can be still in memory.
  ///Refer to class description about cleanup strategies.
  ///* [revalidateHitCount] define how many times cache can be read before call [removeExpired] will
  ///be triggered
  ///* [cleanupDuration] if set internal timer is created. Timer will call [removeExpired]
  ///periodically in cleanupDuration intervals.
  ///* [maxLength] constrains number of entries in cache
  Cache({
    this.entriesExpiration = const Duration(minutes: 10),
    this.revalidateHitCount = -1,
    Duration? cleanupDuration,
    this.maxLength = -1,
  }) {
    timer = cleanupDuration == null
        ? null
        : Timer.periodic(cleanupDuration, (timer) => removeExpired());
  }

  operator [](K key) => read(key);

  operator []=(K key, V value) => write(key, value);

  V? read(K key) {
    V? result;
    final entry = _map[key];
    if (entry != null) {
      if (entry.validUntil.isBefore(DateTime.now())) {
        _map.remove(key);
        if (_firstToRemove == key) {
          _firstToRemove = null;
        }
        _count--;
        assert(_count >= 0, "Internal error");
      } else {
        result = entry.value;
      }
    }
    if (revalidateHitCount > 0) {
      _hitCount++;
      if (_hitCount >= revalidateHitCount) {
        removeExpired();
        _hitCount = 0;
      }
    }
    return result;
  }

  ///Creates or updates entry in cache. Note that this can be time consuming operation if
  ///[maxLength] is set to improper value. If you are using it, tune it to your system needs
  void write(K key, V value) {
    final entry = _map[key];
    final validUntil = DateTime.now().add(entriesExpiration);
    if (entry != null) {
      entry.validUntil = validUntil;
      entry.value = value;
    } else {
      if (maxLength > 0 && maxLength == _count) {
        removeExpired();
        if (maxLength == _count) {
          assert(_firstToRemove != null, "Internal error");
          _map.remove(_firstToRemove);
          _count--;
        }
      }
      _map[key] = CacheEntry(validUntil: validUntil, value: value);
      _count++;
    }
  }

  void remove(K key) {
    if (_map.remove(key) != null) {
      _count--;
      if (_firstToRemove == key) {
        _firstToRemove = null;
      }
      assert(_count >= 0, "Internal error");
    }
  }

  void clear() {
    _map.clear();
    _firstToRemove = null;
    _count = 0;
  }

  ///Traverse whole cache and remove expired entries. This can be time consuming operation, use
  ///wisely.
  void removeExpired() {
    final now = DateTime.now();
    _firstToRemove = null;
    DateTime earliest = DateTime(32000);
    _map.removeWhere((key, value) {
      final expired = value.validUntil.isBefore(now);
      if (expired) {
        _count--;
      } else if (maxLength > 0) {
        if (_firstToRemove == null || value.validUntil.isBefore(earliest)) {
          _firstToRemove = key;
          earliest = value.validUntil;
        }
      }
      return expired;
    });

    assert(_count >= 0, "Internal error");
    assert(_count == _map.length, "Internal error");
  }

  ///Returns approximate entries count in cache.
  int get length => _count;

  ///Remove expired entries, and returns exact entries count in cache. This can be time consuming
  ///operation, consider usage od [length].
  int get exactLength {
    removeExpired();
    return _count;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write("Cache{entryExpireAfter:");
    sb.write(entriesExpiration);
    sb.write(", length:");
    sb.write(_count);
    if (maxLength > 0) {
      sb.write(", maxLength:");
      sb.write(maxLength);
    }
    if (revalidateHitCount > 0) {
      sb.write(", currentHitCount:");
      sb.write(_hitCount);
      sb.write(", revalidateHitCount:");
      sb.write(revalidateHitCount);
    }
    if (timer != null) {
      sb.write(", periodicCleanup: true");
    }
    sb.write("}");
    return sb.toString();
  }
}
