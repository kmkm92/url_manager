import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedUrlProvider =
    StateNotifierProvider<SharedUrlNotifier, List<String>>((ref) {
  return SharedUrlNotifier();
});

class SharedUrlNotifier extends StateNotifier<List<String>> {
  SharedUrlNotifier() : super([]);

  void addUrl(String url) {
    if (!state.contains(url)) {
      state = [...state, url];
    }
  }
}
