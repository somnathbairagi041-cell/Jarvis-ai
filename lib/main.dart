import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JARVIS',
      theme: ThemeData.dark(),
      home: const JarvisHome(),
    );
  }
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController apiController = TextEditingController();

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  String status = "SYSTEM READY";
  String userMessage = "";
  String jarvisReply = "Good day. I am JARVIS.";

  bool listening = false;

  @override
  void initState() {
    super.initState();

    tts.setSpeechRate(0.45);
    tts.setPitch(0.85);
  }

  Future<void> startListening() async {
    if (listening) {
      await speech.stop();

      setState(() {
        listening = false;
        status = "SYSTEM READY";
      });

      return;
    }

    bool available = await speech.initialize();

    if (!available) {
      setState(() {
        status = "MIC NOT AVAILABLE";
      });
      return;
    }

    setState(() {
      listening = true;
      status = "LISTENING...";
    });

    await speech.listen(
      onResult: (result) {
        setState(() {
          messageController.text = result.recognizedWords;
        });

        if (result.finalResult) {
          setState(() {
            listening = false;
          });

          askJarvis(result.recognizedWords);
        }
      },
    );
  }

  Future<void> askJarvis(String question) async {
    if (question.trim().isEmpty) return;

    String apiKey = apiController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        jarvisReply = "Please enter your Gemini API key first.";
        status = "API KEY REQUIRED";
      });

      speak(jarvisReply);
      return;
    }

    setState(() {
      status = "THINKING...";
      userMessage = question;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/"
          "gemini-2.0-flash:generateContent",
        ),
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text":
                    "You are JARVIS, a futuristic personal AI assistant. "
                    "Answer accurately and naturally. "
                    "The user may speak Bengali, Hindi or English. "
                    "Reply in the same language when appropriate. "
                    "Be helpful, concise and friendly. "
                    "Never claim you physically performed an action "
                    "unless the application actually confirms it."
              }
            ]
          },
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": question}
              ]
            }
          ]
        }),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception("API Error ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      final candidates = data["candidates"];

      if (candidates == null || candidates.isEmpty) {
        throw Exception("No AI response");
      }

      final reply =
          candidates[0]["content"]["parts"][0]["text"].toString();

      setState(() {
        jarvisReply = reply;
        status = "SYSTEM READY";
      });

      await speak(reply);
    } catch (e) {
      setState(() {
        jarvisReply =
            "I could not connect to the AI service. "
            "Please check your internet connection and API key.";

        status = "CONNECTION ERROR";
      });

      await speak(jarvisReply);
    }
  }

  Future<void> speak(String text) async {
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070C),

      appBar: AppBar(
        backgroundColor: const Color(0xFF03070C),
        centerTitle: true,
        title: const Text(
          "J.A.R.V.I.S.",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 24,
            letterSpacing: 5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [

            const SizedBox(height: 15),

            // JARVIS CORE

            Center(
              child: Container(
                width: 170,
                height: 170,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  border: Border.all(
                    color: Colors.cyanAccent,
                    width: 3,
                  ),

                  boxShadow: const [
                    BoxShadow(
                      color: Colors.cyanAccent,
                      blurRadius: 35,
                      spreadRadius: 8,
                    ),
                  ],
                ),

                child: const Center(
                  child: Icon(
                    Icons.hub,
                    size: 95,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // API KEY

            TextField(
              controller: apiController,
              obscureText: true,

              decoration: const InputDecoration(
                labelText: "Gemini API Key",
                hintText: "Paste your API key",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // USER MESSAGE

            TextField(
              controller: messageController,

              minLines: 2,
              maxLines: 5,

              decoration: const InputDecoration(
                labelText: "Ask JARVIS",
                hintText: "Type something...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ASK BUTTON

            SizedBox(
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  askJarvis(messageController.text);
                },

                icon: const Icon(Icons.send),

                label: const Text(
                  "ASK JARVIS",
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // MICROPHONE

            SizedBox(
              height: 65,

              child: ElevatedButton.icon(
                onPressed: startListening,

                icon: Icon(
                  listening
                      ? Icons.stop
                      : Icons.mic,
                ),

                label: Text(
                  listening
                      ? "STOP LISTENING"
                      : "SPEAK TO JARVIS",

                  style: const TextStyle(
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // USER

            if (userMessage.isNotEmpty) ...[
              const Text(
                "YOU",
                style: TextStyle(
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                userMessage,
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 25),
            ],

            // JARVIS

            const Text(
              "JARVIS",
              style: TextStyle(
                color: Colors.cyanAccent,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: const Color(0xFF08121C),

                borderRadius:
                    BorderRadius.circular(12),

                border: Border.all(
                  color: Colors.cyanAccent,
                ),
              ),

              child: Text(
                jarvisReply,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "JARVIS V1 • PERSONAL AI ASSISTANT",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    apiController.dispose();

    speech.stop();
    tts.stop();

    super.dispose();
  }
}
