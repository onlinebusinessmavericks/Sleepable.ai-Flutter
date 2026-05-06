import 'package:get/get.dart';

class SelectionFlowController extends GetxController {
  // Store all choices from all screens
  final RxMap<String, List<String>> selections = <String, List<String>>{}.obs;
  final RxDouble buttonScale = 1.0.obs;
  void saveSelection(String key, List<String> values) {
    selections[key] = values;
  }

  void printAll() {
    print("All selections: $selections");
  }

  Map<String, dynamic> get toJson => {
    "selections": selections,
  };
}
