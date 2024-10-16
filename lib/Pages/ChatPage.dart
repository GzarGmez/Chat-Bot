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
  bool _isConnected = true; // Control de conexión
  final String apiKey = 'AIzaSyB0wZHN5PiorXWoBw8VAt1982R3oEzdhXE';
  final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

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

  // Verificar conectividad
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  // Escuchar cambios en la conectividad
  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  // Cargar historial de conversación desde SharedPreferences
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('chat_history') ?? [];
    setState(() {
      _messages.clear(); // Limpiar mensajes existentes antes de cargar
      _messages.addAll(
        savedMessages.map((msg) => Map<String, String>.from(jsonDecode(msg))).toList(),
      );
    });
  }

  // Guardar historial de conversación en SharedPreferences
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedMessages = _messages.map((msg) => jsonEncode(msg)).toList();
    await prefs.setStringList('chat_history', encodedMessages);
  }

  // Llamada a la API de Gemini
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
        print('Error: ${response.statusCode}');
        print('Body: ${response.body}');
        return 'Error en la respuesta del servidor.';
      }
    } catch (e) {
      print('Error en la llamada a la API: $e');
      return 'Error de conexión.';
    }
  }

  // Enviar mensaje y actualizar historial
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
    
    await _saveChatHistory(); // Guardar el historial después de cada mensaje
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Chatbot'),
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

          return Align(
            alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: isUserMessage ? const Color.fromARGB(255, 12, 206, 240) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message['text'] ?? '',
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
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
              onSubmitted: _isConnected ? (value) => _sendMessage(value) : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: _isConnected ? const Color.fromARGB(255, 15, 226, 226) : Colors.grey,
            onPressed: _isConnected
                ? () => _sendMessage(_controller.text)
                : null,
          ),
        ],
      ),
    );
  }
}