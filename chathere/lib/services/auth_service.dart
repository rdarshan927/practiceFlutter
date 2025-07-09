import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../key.dart';

class AuthService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

//   Login Function
Future<String?> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$BACKEND_URL/login'),
    headers: {'content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password})
  );

  if(response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await storage.write(key: 'token', value: data['token']);
    return null;
  } else {
    return jsonDecode(response.body)['error'] ?? 'Login failed';
  }
}

// Registration function
Future<String?> register(String email, String password, String username) async {
  final response = await http.post(Uri.parse('$BACKEND_URL/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email' : email,
      'password': password,
      'username': username
    })
  );

  if(response.statusCode == 201) {
    return null;
  } else {
    return jsonDecode(response.body)['error'] ?? 'Registration failed';
  }
}

// get token from secure storage
Future<String?> getToken() async {
  return await storage.read(key: 'token');
}

// Logout and remove token from secure storage
Future<void> logout() async {
  await storage.delete(key: 'token');
}
}