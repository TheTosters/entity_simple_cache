import 'package:entity_simple_cache/src/cache.dart';

void main() {
  final cache =
      Cache<String, String>(maxLength: 3); //constrain cache to 3 elements
  cache.write("A", "This is A"); //add to cache
  cache["B"] = "This is B"; //add to cache
  print(cache.length); //get approximate size

  cache["C"] = "This is C"; //add to cache
  cache["D"] = "This is D"; //add to cache

  print(cache); //dump cache info
  print("cache for key A is: ${cache.read("A")}"); //read from cache
  print("cache for key B is: ${cache["B"]}"); //read from cache
  print("cache for key C is: ${cache["C"]}"); //read from cache
  print("cache for key D is: ${cache["D"]}"); //read from cache
}
