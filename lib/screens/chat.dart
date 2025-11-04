// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:aplikasi_chat/screens/upgrade.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:aplikasi_chat/screens/profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;


class ChatBot extends StatefulWidget {
  final String email;
  const ChatBot({super.key, required this.email});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot>
    with SingleTickerProviderStateMixin {
  String apiKey = "AIzaSyAm_xCIWqpoe-goifiwvVkVnxWP8hqbX2o";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _input = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _attachKey = GlobalKey();

  final List<_Msg> _messages = [];

  // Timezone toggle
  TimeZone _zone = TimeZone.wib;

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

    _messages.add(
      _Msg(
        text:
            "Haloo👋 Aku merupakan ChatBot yang siap menjadi assisten pribadimu.",
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isUser: true, time: DateTime.now()));
      _input.clear();
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
      final content = [Content.text(text)];
      final resp = await model.generateContent(content);
      final reply = resp.text ?? "Maaf, saya tidak dapat memproses itu.";
      if (!mounted) return;
      setState(() {
        _messages.add(
            _Msg(text: reply, isUser: false, time: DateTime.now()));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(
            text: 'Terjadi kesalahan: $e', isUser: false, time: DateTime.now()));
      });
    }
  }

  Future<void> _showAttachmentMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = _attachKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      overlay.size.width - offset.dx - button.size.width,
      overlay.size.height - offset.dy - button.size.height,
    );

    final action = await showMenu<_AttachAction>(
      context: context,
      position: position,
      color: Colors.grey[900],
      items: [
        PopupMenuItem(
          value: _AttachAction.gallery,
          child: const Row(
            children: [
              Icon(Icons.photo_library, color: Colors.white70, size: 18),
              SizedBox(width: 10),
              Text('Gallery', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: _AttachAction.camera,
          child: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white70, size: 18),
              SizedBox(width: 10),
              Text('Camera', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: _AttachAction.file,
          child: const Row(
            children: [
              Icon(Icons.attach_file, color: Colors.white70, size: 18),
              SizedBox(width: 10),
              Text('File', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );

    switch (action) {
      case _AttachAction.gallery:
        await _pickImageFromGallery();
        break;
      case _AttachAction.camera:
        await _captureFromCamera();
        break;
      case _AttachAction.file:
        await _pickFile();
        break;
      case null:
        break;
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (picked != null) {
        setState(() {
          _messages.add(_Msg(
            imagePath: picked.path,
            isUser: true,
            time: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(
          text: 'Gagal mengambil gambar: $e',
          isUser: false,
          time: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? captured = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (captured != null) {
        setState(() {
          _messages.add(_Msg(
            imagePath: captured.path,
            isUser: true,
            time: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(
          text: 'Kamera gagal dibuka: $e',
          isUser: false,
          time: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      final file = result?.files.single;
      if (file != null && file.path != null) {
        setState(() {
          _messages.add(_Msg(
            filePath: file.path!,
            isUser: true,
            time: DateTime.now(),
            text: file.name,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(
          text: 'Gagal memilih file: $e',
          isUser: false,
          time: DateTime.now(),
        ));
      });
    }
  }

  String _formatTime(DateTime t) {
    final utc = t.toUtc();
    final offsetHours = switch (_zone) {
      TimeZone.wib => 7,
      TimeZone.wita => 8,
      TimeZone.wit => 9,
      TimeZone.london => 0,
    };
    final converted = utc.add(Duration(hours: offsetHours));
    final hh = converted.hour.toString().padLeft(2, '0');
    final mm = converted.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
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
                MaterialPageRoute(builder: (context) => UpgradePage(email: widget.email,)),
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
                MaterialPageRoute(builder: (context) => ChatBot(email: widget.email)),
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
                    email: widget.email,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.grey[800]!, Colors.grey[600]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _ZoneToggle(
                  zone: _zone,
                  onChanged: (z) => setState(() => _zone = z),
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      return Align(
                        alignment:
                            m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78),
                          decoration: BoxDecoration(
                            color: m.isUser ? Colors.blueAccent : Colors.grey[850],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(m.isUser ? 16 : 4),
                              bottomRight: Radius.circular(m.isUser ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.imagePath != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(m.imagePath!),
                                    fit: BoxFit.cover,
                                    width: MediaQuery.of(context).size.width * 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (m.filePath != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: _FileAttachmentTile(
                                    path: m.filePath!,
                                    onOpen: () => OpenFilex.open(m.filePath!),
                                  ),
                                ),
                              if ((m.text ?? '').isNotEmpty) ...[
                                Text(
                                  m.text!,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _formatTime(m.time),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Row(
                    children: [
                      SizedBox(
                        key: _attachKey,
                        child: _RoundedIconButton(
                          icon: Icons.add_circle_outline,
                          tooltip: 'Lampirkan',
                          onTap: _showAttachmentMenu,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _input,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter your message',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(14),
                        ),
                        child: const Icon(Icons.send),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String? text;
  final bool isUser;
  final DateTime time;
  final String? imagePath;
  final String? filePath;
  _Msg({this.text, required this.isUser, required this.time, this.imagePath, this.filePath});
}

enum TimeZone { wib, wita, wit, london }

class _ZoneToggle extends StatelessWidget {
  final TimeZone zone;
  final ValueChanged<TimeZone> onChanged;
  const _ZoneToggle({required this.zone, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = {
      TimeZone.wib: 'WIB',
      TimeZone.wita: 'WITA',
      TimeZone.wit: 'WIT',
      TimeZone.london: 'London',
    };
    final items = TimeZone.values;
    return Wrap(
      spacing: 8,
      children: items.map((z) {
        final selected = z == zone;
        return ChoiceChip(
          label: Text(labels[z]!),
          selected: selected,
          onSelected: (_) => onChanged(z),
          selectedColor: Colors.blueAccent,
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
          backgroundColor: Colors.grey[800],
        );
      }).toList(),
    );
  }
}

class _RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundedIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

enum _AttachAction { gallery, camera, file }

class _FileAttachmentTile extends StatelessWidget {
  final String path;
  final VoidCallback onOpen;
  const _FileAttachmentTile({required this.path, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(path);
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}