# Entity Simple Cache

[![Pub Package](https://img.shields.io/pub/v/entity_simple_cache.svg)](https://pub.dev/packages/entity_simple_cache)
[![GitHub Issues](https://img.shields.io/github/issues/TheTosters/entity_simple_cache.svg)](https://github.com/TheTosters/entity_simple_cache/issues)
[![GitHub Forks](https://img.shields.io/github/forks/TheTosters/entity_simple_cache.svg)](https://github.com/TheTosters/entity_simple_cache/network)
[![GitHub Stars](https://img.shields.io/github/stars/TheTosters/entity_simple_cache.svg)](https://github.com/TheTosters/entity_simple_cache/stargazers)
[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/TheTosters/entity_simple_cache/blob/master/LICENSE)

Small and simple library for caching typed objects and values. It gives few strategies to control
expiration of entries in cache. This lib doesn't use any kind soft/weak linking to track objects.
It's more like a Map with extra wrapper to control when and how to dispose values from it.

## Features
* Read, update, delete and invalidate cache.
* Allows to configure expiration time of entry
* Allows to limit maximum number of entries in cache
* Provides built-in mechanism to periodically remove expired entries
* Provides built-in mechanism to remove expired entries by chosen count of read operations

## Getting started

Here is simple listing of cache usage. For more examples and ideas how to use it please refer to
test folder.

```dart
import 'package:entity_simple_cache/src/cache.dart';

void main() {
  final cache = Cache<String, String>(maxLength: 3);  //constrain cache to 3 elements
  cache.write("A", "This is A");    //add to cache
  cache["B"] = "This is B";         //add to cache
  print(cache.length);              //get approximate size

  cache["C"] = "This is C";         //add to cache
  cache["D"] = "This is D";         //add to cache

  print(cache);                     //dump cache info
  print("cache for key A is: ${cache.read("A")}");  //read from cache
  print("cache for key B is: ${cache["B"]}");       //read from cache
  print("cache for key C is: ${cache["C"]}");       //read from cache
  print("cache for key D is: ${cache["D"]}");       //read from cache
}
```

## Selecting different cache collection

By default proposed cache is using ```HashMap``` as a collection to store data, however it allows
to choose also ```SplayTreeMap```. Here is show code snippet showing how to use it:
```dart
import 'package:entity_simple_cache/src/cache.dart';

void main() {
  final cache = Cache<String, String>(maxLength: 3);            //uses HashMap internally
  final cache2 = SplayTreeCache<String, String>(maxLength: 3);  //uses SplayTreeMap internally
}
```

If for some reasons different type of collection is needed please refer to source how to do it. 
Chosen collection must conform to Dart ```Map``` interface, here is example how to build 
```CustomCache``` class which uses ```LinkedHashMap``` under the hood:

```dart
class CustomCache<K, V> extends TypedCache<K, V> {
  CustomCache({
    super.entriesExpiration = const Duration(minutes: 10),
    super.revalidateHitCount = -1,
    Duration? cleanupDuration,
    super.maxLength = -1,
  }) : super(LinkedHashMap<K, CacheEntry<V>>(), cleanupDuration: cleanupDuration);
}
```