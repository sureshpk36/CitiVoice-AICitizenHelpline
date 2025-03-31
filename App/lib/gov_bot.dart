import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GovChatScreen extends StatefulWidget {
  const GovChatScreen({Key? key}) : super(key: key);

  @override
  _GovChatScreenState createState() => _GovChatScreenState();
}

class _GovChatScreenState extends State<GovChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  bool _showWelcomeScreen = true;

  // API configuration - replace with your actual API key
  final String _apiKey = '0zjmsSJLjr0dvpgoN7l0ivkBCDQ5DgtL';
  final String _apiUrl =
      'https://api.mistral.ai/v1/chat/completions'; // Fixed URL (removed extra 'h')
  final List<Map<String, String>> _conversationHistory = [];

  late AnimationController _welcomeController;
  late Animation<double> _welcomeAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _welcomeAnimation = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeInOut,
    );

    _welcomeController.forward();

    // Add system message to conversation history
    _conversationHistory.add({
      "role": "system",
      "content":
          '''You are an official Indian government services assistant. Your responses should be:
1. Quick, efficient, and to-the-point regarding Indian government programs and procedures
2. Focused on accurate information about Indian bureaucratic processes, forms, and requirements
3. Written in clear, conversational language that's easy to understand
4. Based on current Indian laws, regulations, and governmental structures
5. Free from political opinions or bias

Always respond with information specific to India. Emphasize key points naturally without using asterisks or other markup. Maintain a helpful, human-like tone while keeping responses concise. If asked about non-government topics, politely redirect to Indian government-related information.'''
    });

    // Auto-dismiss welcome screen after delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showWelcomeScreen = false;
      });

      // Add initial greeting
      Future.delayed(const Duration(milliseconds: 300), () {
        _addBotMessage(
            "Hello! I'm your government services assistant. How can I help you today?");
      });
    });
  }

  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') setState(() => _isListening = false);
      },
      onError: (error) => setState(() => _isListening = false),
    );
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _listen() async {
    if (!_isListening) {
      if (_isSpeaking) {
        await _flutterTts.stop();
        setState(() => _isSpeaking = false);
      }

      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              setState(() {
                _textController.text = result.recognizedWords;
                _isListening = false;
              });
              if (_textController.text.isNotEmpty) {
                _handleSubmitted(_textController.text);
              }
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) await _flutterTts.stop();
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(text);
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotMessage(String text) {
    final botMessage = ChatMessage(
      text: text,
      isUserMessage: false,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
    );

    setState(() {
      _messages.insert(0, botMessage);
    });

    botMessage.animationController.forward();
    _speak(text);
  }

  Future<void> _sendMessageToAPI(String message) async {
    setState(() => _isLoading = true);

    try {
      // Add user message to conversation history
      _conversationHistory.add({"role": "user", "content": message});

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'mistral-tiny', // Changed model name to Mistral's model
          'messages': _conversationHistory,
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Updated path to match Mistral API response structure
        final botResponse = data['choices'][0]['message']['content'];
        _conversationHistory.add({"role": "assistant", "content": botResponse});
        _addBotMessage(botResponse);
      } else {
        print('API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        _addBotMessage(
            'Sorry, I encountered an error. Please try again later.');
      }
    } catch (e) {
      print('Exception caught: $e');
      _addBotMessage(
          'Sorry, I encountered an error. Please check your connection and try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSubmitted(String text) {
    _textController.clear();

    if (_isSpeaking) {
      _flutterTts.stop();
      setState(() => _isSpeaking = false);
    }

    final userMessage = ChatMessage(
      text: text,
      isUserMessage: true,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
    );

    _addMessage(userMessage);
    userMessage.animationController.forward();
    _sendMessageToAPI(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcomeScreen) {
      return _buildWelcomeScreen();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _messages[index],
                      ),
              ),
              if (_isLoading)
                Container(
                  height: 3,
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
      floatingActionButton: _isListening
          ? FloatingActionButton(
              onPressed: _listen,
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.mic, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _welcomeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_welcomeAnimation.value * 0.2),
                  child: Opacity(
                    opacity: _welcomeAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        size: 70,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _welcomeAnimation,
              child: const Text(
                "GovServe",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 15),
            FadeTransition(
              opacity: _welcomeAnimation,
              child: const Text(
                "Your government services assistant",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance,
              size: 60,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "How can I assist you today?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Ask about government services, forms, benefits, or any official procedures you need help with.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              _textController.text = "How do I renew my driver's license?";
              _handleSubmitted(_textController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Try an example question",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GovServe",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Government Services Assistant",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isSpeaking) {
                _flutterTts.stop();
                setState(() => _isSpeaking = false);
              } else if (_messages.isNotEmpty && !_messages[0].isUserMessage) {
                _speak(_messages[0].text);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Ask about government services...",
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.mic,
              color: Colors.green[700],
            ),
            onPressed: _listen,
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _textController.text.isNotEmpty
                  ? () => _handleSubmitted(_textController.text)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var message in _messages) {
      message.animationController.dispose();
    }
    _welcomeController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final AnimationController animationController;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUserMessage,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutQuad,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment:
              isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUserMessage) _buildAvatar(isUser: false),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUserMessage ? Colors.green[700] : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isUserMessage ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isUserMessage) _buildAvatar(isUser: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser ? Colors.green[700] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.account_balance,
          color: isUser ? Colors.white : Colors.green[700],
          size: 20,
        ),
      ),
    );
  }
}
