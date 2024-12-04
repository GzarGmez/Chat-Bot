import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isConnected = true; // Control de conectividad
  bool _isWifiEnabled = true; // Control del estado del WiFi
  final String apiKey = 'AIzaSyDNE1Elvhyh9gCtEtC-hgui1x7PGipsovs';
  final String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  bool _preserveChat = true; // Control para guardar o no la conversación

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _checkConnectivity();
    _listenToConnectivityChanges();
  }

  @override
  void dispose() {
    Connectivity().onConnectivityChanged.drain();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
      _isWifiEnabled = connectivityResult == ConnectivityResult.wifi;
    });
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
        _isWifiEnabled = result == ConnectivityResult.wifi;
      });
    });
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('chat_history') ?? [];
    setState(() {
      _messages.clear();
      _messages.addAll(
        savedMessages.map((msg) => Map<String, String>.from(jsonDecode(msg))).toList(),
      );
    });
  }

  Future<void> _saveChatHistory() async {
    if (_preserveChat) {
      final prefs = await SharedPreferences.getInstance();
      final encodedMessages = _messages.map((msg) => jsonEncode(msg)).toList();
      await prefs.setStringList('chat_history', encodedMessages);
    }
  }

  Future<void> _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _messages.clear();
      _preserveChat = false; // No guardar más mensajes
    });
    await prefs.remove('chat_history');
  }

  Future<String?> _callGeminiAPI(String query) async {
    final messagesForContext = _messages.map((msg) => msg['text']!).toList();
    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': messagesForContext.join('\n') + '\nUser: $query'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]['content']?['parts']?[0]['text'] ?? 'Sin respuesta.';
      } else {
        return 'Error en la respuesta del servidor.';
      }
    } catch (e) {
      return 'Error de conexión.';
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _controller.clear();
    });

    if (_isConnected) {
      final response = await _callGeminiAPI(message);
      if (response != null) {
        setState(() {
          _messages.add({'sender': 'bot', 'text': response});
        });
      }
    } else {
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'No hay conexión a internet. Por favor, intenta más tarde.'});
      });
    }

    await _saveChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Mi Chatbot'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () async {
                await _clearChatHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historial de conversación borrado.')),
                );
              },
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 23, 23, 173),
      ),
      body: Column(
        children: [
          _buildChatHistory(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatHistory() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isUserMessage = message['sender'] == 'user';

          return Column(
            crossAxisAlignment:
                isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isUserMessage
                      ? const Color.fromARGB(255, 12, 206, 240)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message['text'] ?? '',
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isUserMessage)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Enviado',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_isConnected && _isWifiEnabled)
                  ? (value) => _sendMessage(value)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: (_isConnected && _isWifiEnabled)
                ? const Color.fromARGB(255, 15, 226, 226)
                : Colors.grey,
            onPressed: (_isConnected && _isWifiEnabled)
                ? () => _sendMessage(_controller.text)
                : null,
          ),
        ],
      ),
    );
  }
}
