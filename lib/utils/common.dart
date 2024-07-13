// Example function to get locally stored token (implement as per your storage mechanism)
import 'package:nb_utils/nb_utils.dart';
import 'package:task_manager_app/utils/constants.dart';

Future<String?> getStoredToken() async {
  return getStringAsync(Constants.firebaseToken);
}

// Example function to store token locally (implement as per your storage mechanism)
Future<void> storeTokenLocally(String token) async {
  setValue(Constants.firebaseToken, token);
}

String getReciever(String user) {
  return user == "Milan" ? "Malu" : "Milan";
}
