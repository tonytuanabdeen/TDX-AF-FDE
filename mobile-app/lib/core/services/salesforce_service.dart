import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SalesforceService {
  SalesforceService(this._prefs);

  final SharedPreferences _prefs;

  Future<String?> getContactId() async {
    return _prefs.getString(AppConstants.sfContactIdKey);
  }

  Future<void> setContactId(String id) async {
    await _prefs.setString(AppConstants.sfContactIdKey, id);
  }

  Future<void> clearContactId() async {
    await _prefs.remove(AppConstants.sfContactIdKey);
  }
}
