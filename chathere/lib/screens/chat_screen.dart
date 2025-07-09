import 'dart:convert';
import 'package:chathere/key.dart';
import 'package:chathere/screens/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as _storage;
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverUsername;
  final IO.Socket? socket;

  const ChatScreen ({
    super.key,
    required this.socket,
    required this.receiverUsername,
    required this.receiverId,
    required this.senderId
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool isLoadingMore = false;
  bool isLoading = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    widget.socket?.on('receiveMessage', (data) {
      setState(() {
        messages.insert(0, {
          'message': data['message'],
          'senderId': data['senderId'],
          'timestamp': data['timestamp']
        });
      });
    });

    _loadChatHistory();

    _scrollController.addListener(() {
      if(_scrollController.position.maxScrollExtent ==
          _scrollController.position.maxScrollExtent &&
          !isLoadingMore) {
        _loadMoreMessages();
      }
    });
  }
  Future<void> _loadChatHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse(
          '$BACKEND_URL/chatHistory/${widget.senderId}/${widget.receiverId}?page=$currentPage'),
        headers: {'Authorization': 'Bearer $token'},
        );

        if(response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            messages.addAll(data.map((msg) {
              return {
                'message': msg['message'],
                'senderId': msg['senderId'],
                'timestamp': msg['timestamp']
            };
            }).toList());
          });
        }

    } catch(e) {
      print('Error loading chat history: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if(isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;
    await _loadChatHistory();
    setState(() {
      isLoadingMore = false;
    });
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if(message.isNotEmpty) {
      final timestamp = DateTime.now().toIso8601String();
      widget.socket?.emit('sendMessage', {
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
        'message': message,
        'timestamp': timestamp,
      });

      setState(() {
        messages.insert(0, {
          'message': message,
          'senderId': widget.senderId,
          'timestamp': timestamp,
        });
      });
      _controller.clear();
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'token');
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  void dispose() {
    widget.socket?.off('receiveMessage');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_sharp,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => HomeScreen())
            );
          },
        ),
        title: Text(
          widget.receiverUsername,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0084FF),
        actions: [
          IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: _logout,
          )
        ],
      ),body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blueAccent, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
          )
        ),
        child: Column(
          children: [
            if(isLoading)
              const LinearProgressIndicator(
                color: Colors.white,
                backgroundColor: Colors.blueAccent,
              ),
            Expanded(
                child: ListView.builder(
                    reverse: true,
                      controller: _scrollController,
                      itemCount: messages.length + (isLoadingMore ? 1:0),
                      itemBuilder: (context, index) {
                      if(isLoadingMore && index == messages.length) {
                        return const Padding(
                            padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator(),),
                        );
                      }
                      final message = messages[index];
                      final isSentByMe = message['senderId'] == widget.senderId;

                      return Align(
                        alignment: isSentByMe
                        ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSentByMe
                                ? Colors.blue.withOpacity(0.8)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['message'],
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 5,),
                              Text(
                                DateFormat('hh:mm a').format(
                                  DateTime.parse(message['timestamp'])
                                ),
                                style: const TextStyle(
                                  fontSize: 12, color: Colors.black
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20)
                        ),
                      )),
                      IconButton(
                          icon: const Icon(Icons.send, color: Colors.blueAccent,),
                          onPressed: _sendMessage,
                      )
                    ],
                  ),
                )
            ],
          ),
        ),
    );
  }
}
