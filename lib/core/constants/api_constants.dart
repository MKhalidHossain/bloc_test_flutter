

import 'dart:io';

class ApiConstants {
  ApiConstants._();

  static const int _port = 8080;

  static String? overrideBaseUrl;

  static String get baseUrl {
    if ( overrideBaseUrl != null) return overrideBaseUrl!;
    if (Platform.isAndroid) {
      return 'http:10.0.2.2: $_port';
    }
    return 'http://localhost:$_port';
  }


  // auth
  static const String logIn = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';


  // booking 
  static const String bookings = '/bookings';
  static  String bookingById (int id) => '/bookings/$id';


  // Admin / testing
  static const String pendingSyncDebug = '/pending-sync'; // server's mock email job queue
  static const String adminExpireToken = '/admin/expire-token';
  static const String adminReset = '/admin/reset';
  static const String adminSeed = '/admin/seed';

}