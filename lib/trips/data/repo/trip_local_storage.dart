import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TripLocalStorage {
  static const String _tripDetailsKey = 'trip_details';
  
  /// Save additional trip details locally
  static Future<void> saveTripDetails(String tripId, Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_tripDetailsKey) ?? '{}';
    final Map<String, dynamic> allDetails = json.decode(existingData);
    
    allDetails[tripId] = details;
    await prefs.setString(_tripDetailsKey, json.encode(allDetails));
  }
  
  /// Get additional trip details
  static Future<Map<String, dynamic>?> getTripDetails(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tripDetailsKey);
    
    if (data == null) return null;
    
    final Map<String, dynamic> allDetails = json.decode(data);
    return allDetails[tripId];
  }
  
  /// Remove trip details
  static Future<void> removeTripDetails(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_tripDetailsKey) ?? '{}';
    final Map<String, dynamic> allDetails = json.decode(existingData);
    
    allDetails.remove(tripId);
    await prefs.setString(_tripDetailsKey, json.encode(allDetails));
  }
  
  /// Get all trip details
  static Future<Map<String, dynamic>> getAllTripDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tripDetailsKey);
    
    if (data == null) return {};
    return json.decode(data);
  }
}
