import 'dart:convert';

import 'package:chathere/key.dart';
import 'package:chathere/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  IO.Socket? socket;
  String? _userToken;
  String? _currentUserId;
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> filteredList = [];
  final TextEditingController searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    searchController.addListener(_filterUsers);
  }

  Future<void> _initialize() async {
    await _loadUserToken();
    await _fetchUsers('');
    _connectSocket();
  }

  Future<void> _loadUserToken() async {
    final token = await _authService.getToken();
    if(token == null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }
    setState(() {
      _userToken = token;
      _currentUserId = _decodeToken(token)['id'];
    });
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if(parts.length != 3) throw Exception('Imvalid token');
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return jsonDecode(payload);
  }

  Future<void> _fetchUsers(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
          Uri.parse('$BACKEND_URL/users'),
          headers: {
            'Authorization': 'Bearer $_userToken',
            'Content-Type': 'application/json'
          }
      );

      if (response.statusCode == 200) {
        final List users = json.decode(response.body);
        setState(() {
          userList = users.cast<Map<String, dynamic>>();
          _filterUsers();
        });
        await _fetchLatestMessages();
      } else {
        Fluttertoast.showToast(
            msg: 'Failed to load users',
            gravity: ToastGravity.BOTTOM
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error fetching users',
          gravity: ToastGravity.BOTTOM
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLatestMessages() async {
    try {
      for(var user in filteredList) {
        final response = await http.get(
          Uri.parse('$BACKEND_URL/chatHistory/$_currentUserId/${user['_id']}?page=1'),
          headers: {
            'Authorization': 'Bearer $_userToken',
            'Content-Type': 'application/json'
          }
        );

        if(response.statusCode == 200){
          final List messages = json.decode(response.body);
          setState(() {
            user['latestMessage'] = messages.isNotEmpty ? messages[0]['message'] : 'No messages yet';
            user['timestamp'] = messages.isNotEmpty ? messages[0]['timestamp'] : null;
          });
        }
      }
    } catch (e) {
      print('Error fetching latest message: $e');
    }
  }

  void _connectSocket() {
    socket = IO.io(
      BACKEND_URL,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'Authorization': 'Bearer $_userToken'})
        .disableAutoConnect()
        .build()
    );

    socket?.connect();

    socket?.onConnect((_){
      print('Connected to socket server');
      if(_currentUserId != null) {
        socket?.emit('userLoggedIn', _currentUserId);
      }
    });

    socket?.onDisconnect((_) => print('Disconnected from socket server'));
    socket?.on('connect_error', (data) => print('Connect error: $data'));
  }

  void _filterUsers() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      filteredList = userList
          .where((user) => user['email'].toString().toLowerCase().contains(query))
          .toList();
    });
  }

  void _startChat(String receiverId, String receiverUsername) {
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => ChatScreen(
    //       senderId: _currentUserId!,
    //       receiverId: receiverId,
    //       receiverUsername: receiverUsername,
    //       socket: socket
    //     ))
    // );
  }

  @override
  void dispose() {
    super.dispose();
    socket?.disconnect();
    searchController.dispose();
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      color: Colors.white.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        title: Text(
          user['email'],
          style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user['lastestMessage']?? 'Tap to chat',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: user['timestamp'] != null
          ? Text(
          _formatTimeStamp(user['timestamp']),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        )
          : null,
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            user['email'][0].toUpperCase(),
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => _startChat(user['_id'], user['email']),
      ),
    );
  }

  String _formatTimeStamp(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if(difference.inDays > 7) return "${date.month}/${date.day}/${date.year}";
    if(difference.inDays >= 1) return "${difference.inDays}d ago";
    if(difference.inHours >= 1) return "${difference.inHours}h ago";
    if(difference.inMinutes >= 1) return "${difference.inMinutes}m ago";
    return "Just now";

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat App",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF008AFF),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.white,),
              onPressed: () async {
                await _authService.logout();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              }, )
        ],
          ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
          )
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by email',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.search, color: Colors.black,)
                ),
              ),
            ),
            _isLoading
            ? const LinearProgressIndicator()
                : Expanded(
                child: filteredList.isEmpty
                    ? const Center(
                  child: Text(
                    "No user found",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                )
                    : ListView.builder(
                    itemCount: filteredList.length,
                  itemBuilder: (context, index) => _buildUserCard(filteredList[index]),
                )
            )
          ],
        ),
      ),
    );
  }
}
