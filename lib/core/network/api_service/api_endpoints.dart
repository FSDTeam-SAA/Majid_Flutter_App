// api_endpoints.dart

// Base configuration
// const String baseUrl = "http://localhost:8001";
const String baseUrl = "https://backend-mattressmatt.onrender.com";
const String musicBaseUrl = "http://72.62.128.141:8001";
//const String baseUrl = "https://qfw86jj6-8001.inc1.devtunnels.ms";//zafor
//const String baseUrl = "http://10.10.5.119:8001";//zafor
const String apiVersion = "api/v1";
String get baseApiUrl => "$baseUrl/$apiVersion";
String get musicApiUrl => "$musicBaseUrl/$apiVersion";

// Auth Endpoints
class AuthEndpoints {
  static String register = "$baseApiUrl/auth/register";
  static String login = "$baseApiUrl/auth/login";
  static String refreshToken = "$baseApiUrl/auth/refresh-token";
  static String forgotPassword = "$baseApiUrl/auth/forget";
  static String resetPassword = "$baseApiUrl/auth/reset-password";
  static String logout = "$baseApiUrl/auth/logout";
  static String deleteAccount = "$baseApiUrl/user/delete-account";
}

// Profile Endpoints
class ProfileEndpoints {
  static String getProfile = "$baseApiUrl/user/profile";
  static String updateProfile = "$baseApiUrl/user/update-profile";
  static String changePassword = "$baseApiUrl/user/change-password";
}

// Settings Endpoints
class SettingsEndpoints {
  static String savePrivacy = "$baseApiUrl/settings/privacy-policy";
  static String saveTerms = "$baseApiUrl/settings/terms-condition";
  static String getPrivacy = "$baseApiUrl/settings/privacy-policy";
  static String getTerms = "$baseApiUrl/settings/terms-condition";
}

// Category Endpoints
class CategoryEndpoints {
  static String create = "$baseApiUrl/category";
  static String all = "$baseApiUrl/category/";
  static String byId(String id) => "$baseApiUrl/category/$id";
  static String update(String id) => "$baseApiUrl/category/$id";
  static String delete(String id) => "$baseApiUrl/category/$id";
}

// Music Endpoints
class MusicEndpoints {
  static String upload = "$musicApiUrl/music";
  static String all = "$musicApiUrl/music";
  static String mostPlayed = "$musicApiUrl/music/mostPlayed";
  static String categoryWise(String categoryId) => "$musicApiUrl/music/categoryWiseMusic/$categoryId";
  static String byId(String id) => "$musicApiUrl/music/$id";
  static String delete(String id) => "$musicApiUrl/music/$id";
}

// Alarm Endpoints
class AlarmEndpoints {
  static String create = "$baseApiUrl/alarm";
  static String all = "$baseApiUrl/alarm";
  static String byId(String id) => "$baseApiUrl/alarm/$id";
  static String update(String id) => "$baseApiUrl/alarm/$id";
  static String delete(String id) => "$baseApiUrl/alarm/$id";
  static String toggle(String id) => "$baseApiUrl/alarm/$id/toggle";
  static String updateWakeUpPhase(String id) => "$baseApiUrl/alarm/$id/wakeUpPhase";
}

// Sleep Goal Endpoints
class SleepGoalEndpoints {
  static String create = "$baseApiUrl/sleep";
  static String active = "$baseApiUrl/sleep/active";
  static String byId(String id) => "$baseApiUrl/sleep/$id";
  static String update(String id) => "$baseApiUrl/sleep/$id";
  static String delete(String id) => "$baseApiUrl/sleep/$id";
}

// Sleep Note Endpoints
class SleepNoteEndpoints {
  static String create = "$baseApiUrl/sleep-note";
  static String all = "$baseApiUrl/sleep-note";
  static String byId(String id) => "$baseApiUrl/sleep-note/$id";
  static String update(String id) => "$baseApiUrl/sleep-note/$id";
  static String delete(String id) => "$baseApiUrl/sleep-note/$id";
}

// Photo Analysis Endpoints
class PhotoAnalysisEndpoints {
  static String analyze = "$baseApiUrl/photo-analyze";
}
