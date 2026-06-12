import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  static const _cloudName = 'dzafty64d';
  static const _apiKey = '517883936462217';
  static const _apiSecret = 'DX1e7rZ_UNHUdCJkGOJU-d_lNQ8';
  static const _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  Future<String> uploadImage(String filePath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signature = _generateSignature(timestamp);

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['api_key'] = _apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['signature'] = signature;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  String _generateSignature(int timestamp) {
    final payload = 'timestamp=$timestamp$_apiSecret';
    final digest = sha1.convert(utf8.encode(payload));
    return digest.toString();
  }
}
