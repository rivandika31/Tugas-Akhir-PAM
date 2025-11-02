// ignore_for_file: deprecated_member_use

import 'package:aplikasi_chat/screens/upgrade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:aplikasi_chat/screens/profile.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot>
    with SingleTickerProviderStateMixin {
  String apiKey = "AIzaSyAm_xCIWqpoe-goifiwvVkVnxWP8hqbX2o";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();


    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text("ChatBot"),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UpgradePage()),
              );
            },
            child: Text(
              "Upgrade ChatBot",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatBot()),
              );
            },
            tooltip: "New Chat",
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    email: "user@example.com",
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[800]!, Colors.grey[600]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LlmChatView(
            suggestions: const [
              "Bagaimana cara memasak pasta?",
              "Berikan saya sebuah lelucon"
            ],
            style: LlmChatViewStyle(
              backgroundColor: Colors.transparent,
              chatInputStyle: ChatInputStyle(
                hintText: "Enter your message",
                hintStyle: TextStyle(color: Colors.white70),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                textStyle: TextStyle(color: Colors.white),
              ),
            ),
            provider: GeminiProvider(
              model: GenerativeModel(
                model: "gemini-2.0-flash",
                apiKey: apiKey,
                systemInstruction: Content.system(
                  "You are a helpful AI assistant that can answer any question accurately and concisely. Always respond in Indonesian language unless specified otherwise.",
                ),
              ),
            ),
            welcomeMessage:
            "Haloo👋 Aku merupakan ChatBot yang siap menjadi assisten pribadimu."
          ),
        ),
      ),
    );
  }
}