import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

// Add the missing enum definition
enum CallState { incoming, connecting, connected, ended }

// Add the missing AudioWavePainter class
class AudioWavePainter extends CustomPainter {
  final List<double> levels;
  final Color color;
  final double animationValue;

  AudioWavePainter(this.levels, this.color, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final double centerY = size.height / 2;
    final double width = size.width;
    final double barWidth = width / levels.length;

    for (int i = 0; i < levels.length; i++) {
      final double scale = 0.5 + 0.5 * sin(i * 0.15 + animationValue * 2 * pi);
      final double barHeight = levels[i] * 180 * scale;

      final double startX = i * barWidth;
      final double topY = centerY - barHeight;
      final double bottomY = centerY + barHeight;

      final RRect bar = RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(startX, topY),
          Offset(startX + barWidth * 0.7, bottomY),
        ),
        const Radius.circular(5),
      );

      canvas.drawRRect(bar, paint);
    }
  }

  @override
  bool shouldRepaint(AudioWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.levels != levels;
  }
}

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({Key? key}) : super(key: key);

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isConnected = false;
  bool _isRinging = false;
  bool _isIncomingCall = true;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isWaitingForResponse = false;

  // Call states
  CallState _callState = CallState.incoming;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _callButtonController;

  // Track conversation for context
  final List<Map<String, String>> _conversationHistory = [];
  String _lastBotResponse = "";

  // Audio visualization values
  final List<double> _audioLevels = List.generate(30, (_) => 0.0);

  // Replace with your actual Mistral API key
  final String _mistralApiKey = '0zjmsSJLjr0dvpgoN7l0ivkBCDQ5DgtL';
  final String _mistralApiUrl = 'https://api.mistral.ai/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initAnimations();

    // Add system message to conversation history
    _conversationHistory.add({
      "role": "system",
      "content":
          """You are a helpful medical assistant speaking on a phone call. Your responses should be:
1. Direct, crisp, and straight to the point
2. Conversational and natural like a human on a phone call
3. Brief and concise (2-3 sentences when possible)
4. Based on established medical knowledge

Speak in a natural, conversational tone. Use everyday language. Avoid formal medical jargon unless necessary.

Don't say "I'm not a replacement for a doctor" unless specifically asked about your limitations.

When asked medical questions, provide clear, actionable information without unnecessary explanations or caveats.

For non-medical questions, politely redirect: "I'm focused on helping with health questions. What medical concern can I help with?"

If the situation sounds urgent or serious, briefly suggest seeking immediate medical attention."""
    });

    // Load and prepare the audio file early in initState
    _prepareAudio();
  }

  void _prepareAudio() async {
    try {
      // Check if the AudioPlayer is already initialized
      await _audioPlayer.setSource(AssetSource('sounds/phone_ring.mp3'));
      _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Start ringing sound with slight delay
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _isRinging = true;
        });
        _playRingtone();
      });
    } catch (e) {
      print('Error preparing audio: $e');
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    _callButtonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("Speech status: $status");
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
          // Process the speech result
          _processSpeechResult();
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
    await _flutterTts.setSpeechRate(0.55);
    await _flutterTts.setVolume(_isSpeakerOn ? 1.0 : 0.5);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
      _simulateAudioLevels(true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
      // Reset audio levels
      _simulateAudioLevels(false);

      // If connected and not listening, auto-start listening after bot finishes speaking
      if (_isConnected && !_isListening && !_isMuted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _startListening();
        });
      }
    });
  }

  void _playRingtone() async {
    try {
      // Make sure the volume is set properly
      await _audioPlayer.setVolume(0.8);

      // Play the audio
      await _audioPlayer.resume();

      // Log to verify playback started
      print('Ringtone playback started');
    } catch (e) {
      print('Error playing ringtone: $e');

      // Fallback method if the first approach fails
      try {
        await _audioPlayer.play(AssetSource('sounds/phone_ring.mp3'),
            volume: 0.8);
        print('Fallback ringtone playback started');
      } catch (e2) {
        print('Fallback also failed: $e2');
      }
    }
  }

  void _stopRingtone() async {
    try {
      await _audioPlayer.stop();
      print('Ringtone stopped');
    } catch (e) {
      print('Error stopping ringtone: $e');
    }

    setState(() {
      _isRinging = false;
    });
  }

  void _answerCall() {
    _stopRingtone();
    setState(() {
      _callState = CallState.connecting;
    });

    // Simulate connecting...
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isConnected = true;
        _callState = CallState.connected;
      });

      // Start the call with initial greeting
      Future.delayed(const Duration(milliseconds: 800), () {
        _sendMessageToMistral("Hello, I need some medical advice");
      });
    });
  }

  void _endCall() {
    _stopRingtone();
    if (_isSpeaking) {
      _flutterTts.stop();
    }
    if (_isListening) {
      _speech.stop();
    }

    setState(() {
      _isConnected = false;
      _callState = CallState.ended;
    });

    // Show call ended for a moment, then pop the screen
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  Future<void> _startListening() async {
    if (!_isListening && !_isMuted) {
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
        _simulateAudioLevels(true);

        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              setState(() {
                _isListening = false;
              });
              _simulateAudioLevels(false);

              // Send recognized text to API
              if (result.recognizedWords.isNotEmpty) {
                _sendMessageToMistral(result.recognizedWords);
              }
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _simulateAudioLevels(false);
    }
  }

  void _processSpeechResult() {
    // This will be automatically called when speech recognition is complete
  }

  Future<void> _speak(String text) async {
    if (_isMuted) return; // Don't speak if muted

    // Stop any ongoing TTS before starting new one
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    setState(() {
      _isSpeaking = true;
      _lastBotResponse = text;
    });

    await _flutterTts.speak(text);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    if (_isMuted) {
      // If muting while speaking, stop the speech
      if (_isSpeaking) {
        _flutterTts.stop();
        setState(() {
          _isSpeaking = false;
        });
      }

      // If muting while listening, stop listening
      if (_isListening) {
        _speech.stop();
        setState(() {
          _isListening = false;
        });
      }
    } else {
      // If unmuting, start listening after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _startListening();
      });
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });

    // Update TTS volume based on speaker state
    _flutterTts.setVolume(_isSpeakerOn ? 1.0 : 0.5);
  }

  void _simulateAudioLevels(bool active) {
    if (active) {
      // Start a timer to update audio levels
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isListening && !_isSpeaking) {
          timer.cancel();
          setState(() {
            for (int i = 0; i < _audioLevels.length; i++) {
              _audioLevels[i] = 0.0;
            }
          });
          return;
        }

        setState(() {
          for (int i = 0; i < _audioLevels.length; i++) {
            _audioLevels[i] = (0.1 +
                    (0.8 * (i % 3 == 0 ? 0.7 : 0.4)) *
                        (i % 2 == 0 ? 0.8 : 1.0)) *
                (0.3 +
                    0.7 *
                        (DateTime.now().millisecondsSinceEpoch % 1000) /
                        1000);
          }
        });
      });
    }
  }

  Future<void> _sendMessageToMistral(String message) async {
    try {
      // Set waiting state to true to show loading animation
      setState(() {
        _isWaitingForResponse = true;
      });

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

      // Set waiting state to false as we got a response
      setState(() {
        _isWaitingForResponse = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['choices'][0]['message']['content'];

        // Add bot response to conversation history
        _conversationHistory.add({"role": "assistant", "content": botResponse});

        _speak(botResponse);
      } else {
        _speak('Sorry, I encountered an error. Please try again later.');
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isWaitingForResponse = false;
      });
      _speak(
          'Sorry, I encountered an error. Please check your internet connection and try again.');
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6A11CB).withOpacity(0.8),
                  const Color(0xFF2575FC).withOpacity(0.8),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Audio visualization waves
          if (_isConnected && (_isListening || _isSpeaking))
            Positioned.fill(
              child: _buildAudioWaves(),
            ),

          // Main call UI
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Avatar and call info
                _buildCallerInfo(),

                const Spacer(flex: 3),

                // Call actions
                _buildCallActions(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      children: [
        // Avatar with status indicator
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing ring for incoming call
              if (_isRinging || _callState == CallState.connecting)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 140 + (_pulseController.value * 20),
                      height: 140 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(
                              0.3 - (_pulseController.value * 0.3)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),

              // Second pulsing ring
              if (_isRinging || _callState == CallState.connecting)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 160 + (_pulseController.value * 30),
                      height: 160 + (_pulseController.value * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(
                              0.2 - (_pulseController.value * 0.2)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),

              // Medicine icon
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A11CB).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 45,
                  color: Colors.white,
                ),
              ),

              // Connected/active indicator
              if (_isConnected && (_isListening || _isSpeaking))
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.green : Colors.blue)
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Add loading indicator here
        if (_isWaitingForResponse && _callState == CallState.connected)
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 40,
            height: 40,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),

        const SizedBox(height: 24),

        // Caller name
        const Text(
          "MediBot AI",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Call status
        Text(
          _getCallStatusText(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCallActions() {
    if (_callState == CallState.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decline call button
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _endCall,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 40),

          // Answer call button
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _answerCall,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mute button
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isMuted
                  ? Colors.red.withOpacity(0.8)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: _isMuted
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggleMute,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white.withOpacity(_isMuted ? 1.0 : 0.7),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // End call button
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _endCall,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          // Speaker button
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isSpeakerOn
                  ? Colors.blue.withOpacity(0.8)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: _isSpeakerOn
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggleSpeaker,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Icon(
                    _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    color: Colors.white.withOpacity(_isSpeakerOn ? 1.0 : 0.7),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildAudioWaves() {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: CustomPaint(
          painter: AudioWavePainter(
            _audioLevels,
            _isListening ? Colors.green : Colors.blue,
            _waveAnimation.value,
          ),
        ),
      ),
    );
  }

  String _getCallStatusText() {
    switch (_callState) {
      case CallState.incoming:
        return "Incoming call...";
      case CallState.connecting:
        return "Connecting...";
      case CallState.connected:
        if (_isMuted) {
          return "Muted";
        } else if (_isListening) {
          return "Listening...";
        } else if (_isWaitingForResponse) {
          return "Processing...";
        } else if (_isSpeaking) {
          return "Speaking...";
        } else {
          return "Connected";
        }
      case CallState.ended:
        return "Call ended";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _speech.cancel();
    _flutterTts.stop();
    _pulseController.dispose();
    _waveController.dispose();
    _callButtonController.dispose();
    super.dispose();
  }
}
