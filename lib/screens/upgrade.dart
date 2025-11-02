// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:aplikasi_chat/screens/chat.dart';

class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage>
    with SingleTickerProviderStateMixin {
  bool isUSD = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String formatPrice(double usdPrice) {
    if (isUSD) {
      return '\$${usdPrice.toStringAsFixed(0)}/month';
    } else {
      final idrPrice = usdPrice * 16658;
      return 'Rp${idrPrice.toStringAsFixed(0)}/month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Upgrade ChatBot"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChatBot()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(
                  'IDR',
                  style: TextStyle(
                    color: !isUSD ? Colors.white : Colors.white38,
                    fontWeight: !isUSD ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Switch(
                  value: isUSD,
                  onChanged: (value) {
                    setState(() {
                      isUSD = value;
                    });
                  },
                  activeColor: Colors.blueAccent,
                  inactiveThumbColor: Colors.grey[700],
                  inactiveTrackColor: Colors.grey[600],
                ),
                Text(
                  'USD',
                  style: TextStyle(
                    color: isUSD ? Colors.white : Colors.white38,
                    fontWeight: isUSD ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[850]!, Colors.grey[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildUpgradeCard(
                  title: 'Basic Plan',
                  features: [
                    'Unlimited Messages',
                    'Basic AI Responses',
                    '24/7 Support'
                  ],
                  price: formatPrice(5),
                  gradientColors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
                ),
                const SizedBox(height: 16),
                _buildUpgradeCard(
                  title: 'Pro Plan',
                  features: [
                    'Advanced AI Responses',
                    'Priority Support',
                    'Custom Chat Themes'
                  ],
                  price: formatPrice(15),
                  gradientColors: [Colors.teal[700]!, Colors.tealAccent[700]!],
                ),
                const SizedBox(height: 16),
                _buildUpgradeCard(
                  title: 'Premium Plan',
                  features: [
                    'Expert AI Assistance',
                    'Voice Chat Support',
                    'API Access'
                  ],
                  price: formatPrice(30),
                  gradientColors: [Colors.orange[800]!, Colors.deepOrangeAccent],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeCard({
    required String title,
    required List<String> features,
    required String price,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
