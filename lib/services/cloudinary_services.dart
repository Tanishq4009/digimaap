import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads seal-evidence photos to Cloudinary and returns the public
/// `secure_url`, which is what gets sent over the socket / stored in
/// SharedPreferences instead of a base64 blob.
class CloudinaryService {
  static const String cloudName = 'n4z38xqk';
  static const String uploadPreset = 'sih_preset';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
          ),
        );

      final response = await request.send();
      final responseBytes = await response.stream.toBytes();
      final result = utf8.decode(responseBytes);

      if (response.statusCode == 200) {
        final jsonResponse =
            jsonDecode(result) as Map<String, dynamic>;
        return jsonResponse['secure_url'] as String?;
      } else {
        // ignore: avoid_print
        print(
          'Cloudinary upload failed (${response.statusCode}): $result',
        );
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
