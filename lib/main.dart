import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'jarvis_brain.dart';

void main() {
  runApp(const JarvisV2());
}

class JarvisV2 extends StatelessWidget {
  const JarvisV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jarvis v2',
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
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();
  final JarvisBrain brain = JarvisBrain();

  bool listening = false;
  String status = 'JARVIS V2 READY';
  String userMessage = '';
  String response = '';

  @override
  void initState() {
    super.initState();
    _setupVoice();
  }

  Future<void> _setupVoice() async {
    await tts.setSpeechRate(0.45);
    await tts.setPitch(0.85);
  }

  Future<void> startListening() async {
    if (listening) {
      await speech.stop();
      setState(() {
        listening = false;
        status = 'JARVIS V2 READY';
      });
      return;
    }

    final available = await speech.initialize();

    if (!available) {
      setState(() {
        status = 'MICROPHONE NOT AVAILABLE';
      });
      return;
    }

    setState(() {
      listening = true;
      status = 'LISTENING...';
    });

    await speech.listen(
      onResult: (result) {
        setState(() {
          userMessage = result.recognizedWords;
        });

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _processCommand(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _processCommand(String command) async {
    await speech.stop();

    setState(() {
      listening = false;
      status = 'THINKING...';
    });

    final answer = brain.reply(command);

    setState(() {
      response = answer;
      status = 'JARVIS V2 READY';
    });

    await tts.speak(answer);
  }

  @override
  void dispose() {
    speech.stop();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS v2'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (userMessage.isNotEmpty)
              Text(
                'You: $userMessage',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            if (response.isNotEmpty)
              Text(
                'Jarvis: $response',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 40),
            FloatingActionButton.large(
              onPressed: startListening,
              child: Icon(
                listening ? Icons.stop : Icons.mic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
