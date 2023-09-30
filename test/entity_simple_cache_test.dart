import 'dart:math';

import 'package:entity_simple_cache/entity_simple_cache.dart';
import 'package:test/test.dart';

void main() {
  group('Check cache max size constrain', () {
    test('Addition', () {
      Cache<int, int> cache = Cache(maxLength: 500);
      for (int t = 0; t < 1000; t++) {
        cache[t] = t;
        expect(cache.length, lessThanOrEqualTo(500));
      }
    });
    test('Mixed', () {
      Cache<int, int> cache = Cache(maxLength: 500);
      Random rand = Random(1000);
      for (int t = 0; t < 3000; t++) {
        if (rand.nextInt(100) < 30) {
          cache.remove(t % 1000);
        } else {
          cache[t % 1000] = t;
        }
        expect(cache.length, lessThanOrEqualTo(500));
      }
    });
  });
  group('Check cache expiration', () {
    test('Implicit', () async {
      Cache<int, int> cache =
          Cache(entriesExpiration: Duration(milliseconds: 300));
      for (int t = 0; t < 1000; t++) {
        cache[t] = t;
      }
      await Future.delayed(Duration(milliseconds: 301));
      expect(cache.length, greaterThan(0));
      expect(cache.exactLength, 0);
    });
    test('On demand', () async {
      Cache<int, int> cache =
          Cache(entriesExpiration: Duration(milliseconds: 300));
      for (int t = 0; t < 1000; t++) {
        cache[t] = t;
      }
      await Future.delayed(Duration(milliseconds: 301));
      cache.removeExpired();
      expect(cache.length, 0);
    });
    test('Triggered by hit count', () async {
      Cache<int, int> cache = Cache(
        entriesExpiration: Duration(milliseconds: 300),
        revalidateHitCount: 1,
      );
      for (int t = 0; t < 1000; t++) {
        cache[t] = t;
      }
      await Future.delayed(Duration(milliseconds: 301));
      cache.read(0);
      expect(cache.length, 0);
    });
    test('Triggered by timer', () async {
      Cache<int, int> cache = Cache(
        entriesExpiration: Duration(milliseconds: 300),
        cleanupDuration: Duration(milliseconds: 301),
      );
      for (int t = 0; t < 1000; t++) {
        cache[t] = t;
      }
      await Future.delayed(Duration(milliseconds: 310));
      expect(cache.length, 0);
    });
    test('Values should be accessible if not expired', () async {
      Cache<int, int> cache = Cache(
        entriesExpiration: Duration(milliseconds: 300),
        cleanupDuration: Duration(milliseconds: 301),
      );
      for (int t = 0; t < 1000; t++) {
        cache[t] = t;
      }
      for (int t = 0; t < 1000; t++) {
        expect(cache.read(t), t);
      }
      await Future.delayed(Duration(milliseconds: 310));
      for (int t = 0; t < 1000; t++) {
        expect(cache.read(t), null);
      }
    });
  });
  group('Data consistency', () {
    test('Values should updated', () async {
      Cache<int, int> cache = Cache();
      cache[1] = 1;
      cache[1] = 2;
      expect(cache[1], 2);
      expect(cache.length, 1);
      expect(cache.exactLength, 1);
    });
    test('Values should removable', () async {
      Cache<int, int> cache = Cache();
      cache[1] = 1;
      cache[2] = 2;
      cache.remove(1);
      expect(cache[1], null);
      expect(cache[2], 2);
      expect(cache.length, 1);
      expect(cache.exactLength, 1);
    });
  });
}
