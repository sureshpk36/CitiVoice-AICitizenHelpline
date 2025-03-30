import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

class LawChatScreen extends StatefulWidget {
  const LawChatScreen({Key? key}) : super(key: key);

  @override
  _LawChatScreenState createState() => _LawChatScreenState();
}

class _LawChatScreenState extends State<LawChatScreen>
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

  // Replace with your actual Mistral API key
  final String _mistralApiKey = '0zjmsSJLjr0dvpgoN7l0ivkBCDQ5DgtL';
  final String _mistralApiUrl = 'https://api.mistral.ai/v1/chat/completions';

  // Track conversation history for context
  final List<Map<String, String>> _conversationHistory = [];

  // Animation controllers
  late AnimationController _typingController;
  late AnimationController _pulseController;
  late AnimationController _welcomeController;
  late Animation<double> _welcomeAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    // Initialize animation controllers
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
          """You are a helpful, responsible legal chatbot. Your responses should be:
1. Informative but cautious
2. Based on established legal principles and knowledge
3. Clear that you are not a replacement for professional legal advice
4. Free from specific legal recommendations for individual cases
Be empathetic, clear, and concise in your responses. Never mention being an artificial intelligence with a knowledge cutoff.
Keep it short and concise, do not include asterisks and other symbols. If we don't talk about legal matters, tell the user you only know about legal topics.
"""
    });

    // Start with welcome screen, then auto-add the first message after delay
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showWelcomeScreen = false;
      });

      // Add initial greeting from the bot after welcome screen dismisses
      Future.delayed(const Duration(milliseconds: 500), () {
        _addBotMessage(
            "Hello! I'm your legal assistant. How can I help you today?");
      });
    });
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        setState(() {
          _isListening = false;
        });
      },
    );

    if (!available) {
      print('Speech recognition not available');
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4); // Increased speech rate
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _listen() async {
    if (!_isListening) {
      // Stop any ongoing TTS before listening
      if (_isSpeaking) {
        await _flutterTts.stop();
        setState(() {
          _isSpeaking = false;
        });
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
              // Auto-send message when speech recognition is complete
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
    // Stop any ongoing TTS before starting new one
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    setState(() {
      _isSpeaking = true;
    });

    await _flutterTts.speak(text);
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });

    // Scroll to see new message
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
    _speak(text); // Text-to-speech for bot responses
  }

  Future<void> _sendMessageToMistral(String message) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add user message to conversation history
      _conversationHistory.add({"role": "user", "content": message});

      final response = await http.post(
        Uri.parse(_mistralApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_mistralApiKey',
        },
        body: jsonEncode({
          'model': 'mistral-large-latest',
          'messages': _conversationHistory,
          'temperature': 0.4,
          'top_p': 0.95,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['choices'][0]['message']['content'];

        // Add bot response to conversation history
        _conversationHistory.add({"role": "assistant", "content": botResponse});

        _addBotMessage(botResponse);
      } else {
        _addBotMessage(
            'Sorry, I encountered an error. Please try again later.');
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _addBotMessage(
          'Sorry, I encountered an error. Please check your internet connection and try again.');
      print('Exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubmitted(String text) {
    _textController.clear();

    // Stop any ongoing speech
    if (_isSpeaking) {
      _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
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
    _sendMessageToMistral(text);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_showWelcomeScreen) {
      return _buildWelcomeScreen(isDarkMode);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDarkMode),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _messages[index],
                      ),
              ),
              if (_isLoading)
                Container(
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF0C4A6E),
                    ),
                  ),
                ),
              _buildInputArea(isDarkMode),
            ],
          ),
        ),
      ),
      floatingActionButton: _isListening
          ? Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0E7490), Color(0xFF0284C7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E7490).withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _listen,
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.3),
                      child:
                          const Icon(Icons.mic, color: Colors.white, size: 28),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildWelcomeScreen(bool isDarkMode) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0C4A6E),
              Color(0xFF0284C7),
            ],
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
                      child: Icon(
                        Icons.gavel,
                        size: 70,
                        color: const Color(0xFF0C4A6E),
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
                "LawBot AI",
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
                "Your personal legal assistant",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _welcomeAnimation,
              child: Container(
                width: 80,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
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
              Icons.balance,
              size: 60,
              color: const Color(0xFF0C4A6E),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Ask me anything about legal matters",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "I can help you understand legal concepts, provide general information about laws, and offer guidance on when to consult a lawyer.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          InkWell(
            onTap: () {
              _textController.text = "What should I know about copyright law?";
              _handleSubmitted(_textController.text);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C4A6E).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C4A6E),
            Color(0xFF0284C7),
          ],
        ),
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
              Icons.gavel,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LawBot AI",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Your legal companion",
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
                setState(() {
                  _isSpeaking = false;
                });
              } else if (_messages.isNotEmpty && !_messages[0].isUserMessage) {
                _speak(_messages[0].text);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Ask me about legal matters...",
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black38,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _textController.text.isNotEmpty
                    ? [const Color(0xFF0C4A6E), const Color(0xFF0284C7)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _textController.text.isNotEmpty
                    ? () => _handleSubmitted(_textController.text)
                    : null,
                child: const Center(
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _listen,
                child: Center(
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
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
    _typingController.dispose();
    _pulseController.dispose();
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutQuart,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutQuart,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUserMessage) _buildAvatar(isDarkMode, isUser: false),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isUserMessage
                          ? [const Color(0xFF0C4A6E), const Color(0xFF0284C7)]
                          : isDarkMode
                              ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF0F172A)
                                ]
                              : [Colors.white, Colors.white],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUserMessage
                          ? const Radius.circular(20)
                          : const Radius.circular(0),
                      bottomRight: isUserMessage
                          ? const Radius.circular(0)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUserMessage
                            ? const Color(0xFF0C4A6E).withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUserMessage) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color:
                                  isDarkMode ? Colors.blue[300] : Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "LawBot AI",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 1,
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                          margin: const EdgeInsets.only(bottom: 6),
                        ),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: isUserMessage
                              ? Colors.white
                              : isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isUserMessage) _buildAvatar(isDarkMode, isUser: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDarkMode, {required bool isUser}) {
    if (isUser) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C4A6E).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 18,
          ),
        ),
      );
    } else {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.balance,
            color: const Color(0xFF0C4A6E),
            size: 18,
          ),
        ),
      );
    }
  }
}
