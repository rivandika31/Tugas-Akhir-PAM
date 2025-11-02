// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:aplikasi_chat/services/notification_service.dart';

class PaymentFormPage extends StatefulWidget {
  final String planName;
  final String priceLabel;
  const PaymentFormPage({super.key, required this.planName, required this.priceLabel});

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expController = TextEditingController();

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _cardController.dispose();
    _cvvController.dispose();
    _expController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If user backgrounds the app without completing payment, remind them
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.detached) && !_completed) {
      NotificationService.instance
          .showPaymentReminder(planName: widget.planName);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    await Future.delayed(const Duration(milliseconds: 600)); // simulate network
    setState(() => _completed = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Payment success!'),
      backgroundColor: Colors.green,
    ));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_completed) {
          await NotificationService.instance
              .showPaymentReminder(planName: widget.planName);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pay ${widget.planName}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Total: ${widget.priceLabel}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name on Card'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cardController,
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.length < 12) ? 'Invalid card number' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expController,
                        decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(labelText: 'CVV'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.length < 3) ? 'Invalid CVV' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.lock),
                  label: const Text('Pay Now'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
