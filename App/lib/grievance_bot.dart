import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class GrievanceChatScreen extends StatefulWidget {
  const GrievanceChatScreen({Key? key}) : super(key: key);

  @override
  _GrievanceChatScreenState createState() => _GrievanceChatScreenState();
}

class _GrievanceChatScreenState extends State<GrievanceChatScreen>
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
  bool _isFormFilled = false;
  Map<String, String> _grievanceDetails = {
    'description': '',
    'location': '',
    'date': '',
    'contactInfo': '',
  };
  String _currentPrompt = 'description';
  List<String> _prompts = [
    'description',
    'location',
    'date',
    'contactInfo',
  ];

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _welcomeController;
  late Animation<double> _welcomeAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

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

    // Auto-dismiss welcome screen
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showWelcomeScreen = false;
      });

      // Add initial greeting and request description
      Future.delayed(const Duration(milliseconds: 500), () {
        _addBotMessage(
            "Hello! I'm your grievance filing assistant. Please describe your problem or concern in detail.");
      });
    });
  }

  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
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
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(text);
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });

    // Auto-scroll
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

  void _handleUserInput(String input) {
    if (!_isFormFilled) {
      _grievanceDetails[_currentPrompt] = input;
      int currentIndex = _prompts.indexOf(_currentPrompt);

      if (currentIndex < _prompts.length - 1) {
        _currentPrompt = _prompts[currentIndex + 1];
        String nextPrompt = '';

        switch (_currentPrompt) {
          case 'location':
            nextPrompt =
                "Thank you. Where did this issue occur? Please provide the specific location.";
            break;
          case 'date':
            nextPrompt =
                "When did this issue happen? Please provide the date and approximate time.";
            break;
          case 'contactInfo':
            nextPrompt =
                "Please provide your contact information (name, phone, email) for follow-up.";
            break;
        }

        _addBotMessage(nextPrompt);
      } else {
        setState(() => _isFormFilled = true);
        _generateGrievanceLetter();
      }
    } else {
      _addBotMessage(
          "Thank you for your additional information. I've updated your grievance letter.");
    }
  }

  void _generateGrievanceLetter() {
    String letterContent = '''
To Whom It May Concern,

Subject: Formal Grievance Filing

I am writing to formally file a grievance regarding an issue that I recently experienced.

Description of Issue:
${_grievanceDetails['description']}

Location of Incident:
${_grievanceDetails['location']}

Date and Time of Incident:
${_grievanceDetails['date']}

I kindly request that this matter be addressed promptly. This situation has caused significant inconvenience and I believe it requires immediate attention.

Contact Information:
${_grievanceDetails['contactInfo']}

Please acknowledge receipt of this grievance and provide information regarding the next steps in this process. I am available to provide any additional information that may be required.

Thank you for your attention to this matter.

Sincerely,
[Your signature will be added here]''';

    _addBotMessage(
        "Thank you for providing all the necessary details. I've prepared a grievance letter for you:\n\n$letterContent\n\nYou can copy this letter to file your grievance. Is there anything else you'd like to add or modify?");
  }

  Future<void> _processUserMessage(String message) async {
    setState(() => _isLoading = true);

    try {
      _handleUserInput(message);
    } catch (e) {
      _addBotMessage('Sorry, I encountered an error. Please try again later.');
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
    _processUserMessage(text);
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
                    const Color(0xFF1E1E2C),
                    const Color(0xFF0D0D17),
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
                      const Color(0xFF6C5CE7),
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
                  colors: [Color(0xFF6C5CE7), Color(0xFF5E54E7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.5),
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
              Color(0xFF6C5CE7),
              Color(0xFF5E54E7),
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
                        Icons.support_agent,
                        size: 70,
                        color: const Color(0xFF6C5CE7),
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
                "Grievance Helper",
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
                "Your voice will be heard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
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
              color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
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
              Icons.record_voice_over,
              size: 60,
              color: const Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Let me help file your grievance",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E1E2C),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Describe your issue, and I'll guide you through creating a formal grievance letter.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.5,
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
            Color(0xFF6C5CE7),
            Color(0xFF5E54E7),
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
              Icons.support_agent,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Grievance Helper",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "We're here to help",
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
        color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
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
                  hintText: "Enter your response...",
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
                    ? [const Color(0xFF6C5CE7), const Color(0xFF5E54E7)]
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
                colors: [Color(0xFF6C5CE7), Color(0xFF5E54E7)],
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
                          ? [const Color(0xFF6C5CE7), const Color(0xFF5E54E7)]
                          : isDarkMode
                              ? [
                                  const Color(0xFF28273C),
                                  const Color(0xFF1E1E2C)
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
                            ? const Color(0xFF6C5CE7).withOpacity(0.3)
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
                              color: isDarkMode
                                  ? Colors.purple[300]
                                  : Colors.purple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Grievance Helper",
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
            colors: [Color(0xFF6C5CE7), Color(0xFF5E54E7)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.3),
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
          color: isDarkMode ? const Color(0xFF28273C) : Colors.white,
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
            Icons.support_agent,
            color: const Color(0xFF6C5CE7),
            size: 18,
          ),
        ),
      );
    }
  }
}
