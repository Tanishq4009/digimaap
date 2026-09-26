import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EnvConfig {
  static String webPortalUrl = 'https://emaap-web-portal.onrender.com';
  static String sealValidationApiUrl = 'https://digimaap-seal-validation.onrender.com';
  static String cloudinaryApiUrl = 'https://api.cloudinary.com/v1_1';

  static Future<void> load() async {
    try {
      final String content = await rootBundle.loadString('.env');
      final Map<String, String> env = _parseEnv(content);

      if (env.containsKey('EMAAP_WEB_PORTAL_URL') && env['EMAAP_WEB_PORTAL_URL']!.isNotEmpty) {
        webPortalUrl = env['EMAAP_WEB_PORTAL_URL']!;
      }
      if (env.containsKey('SEAL_VALIDATION_API_URL') && env['SEAL_VALIDATION_API_URL']!.isNotEmpty) {
        sealValidationApiUrl = env['SEAL_VALIDATION_API_URL']!;
      }
      if (env.containsKey('CLOUDINARY_API_URL') && env['CLOUDINARY_API_URL']!.isNotEmpty) {
        cloudinaryApiUrl = env['CLOUDINARY_API_URL']!;
      }

      debugPrint(
        '[EnvConfig] Successfully loaded environment configuration from .env: webPortalUrl=$webPortalUrl, sealValidationApiUrl=$sealValidationApiUrl',
      );
    } catch (e) {
      debugPrint('[EnvConfig] .env file load notice (using default fallback URLs): $e');
    }
  }

  static Map<String, String> _parseEnv(String content) {
    final Map<String, String> map = {};
    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final idx = line.indexOf('=');
      if (idx > 0) {
        final key = line.substring(0, idx).trim();
        final val = line.substring(idx + 1).trim();
        map[key] = val;
      }
    }
    return map;
  }
}
