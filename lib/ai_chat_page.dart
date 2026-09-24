
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_page.dart';

// ============================================================
// FAITH AI / FAITHI COPILOT
// Current frontend for Faithi backend v4.4+
//
// - Uses current Railway production endpoint
// - Voice input + TTS output
// - Live Supabase services/colors for UI + booking
// - Uses exactly one AI model: meta-llama/Llama-3.1-8B-Instruct
// - One-model AI path only
// - Displays real service images returned/matched from Supabase
// - Preserves conversation history and customer preferences
// ============================================================

// ============================================================
// 1. SHELL
// ============================================================

class FaithAICopilotShell extends StatefulWidget {
  const FaithAICopilotShell({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<FaithAICopilotShell> createState() => _FaithAICopilotShellState();
}

class _FaithAICopilotShellState extends State<FaithAICopilotShell> {
  bool _isOpen = false;

  void _toggleChat() => setState(() => _isOpen = !_isOpen);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    alignment: Alignment.bottomRight,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _isOpen
                    ? FaithAICopilotPanel(
                        key: const ValueKey('panel'),
                        navigatorKey: widget.navigatorKey,
                        onClose: _toggleChat,
                        onMinimize: _toggleChat,
                      )
                    : _CopilotLauncher(
                        key: const ValueKey('launcher'),
                        hasActiveChat:
                            FaithCopilotController.instance.hasChatHistory,
                        onTap: _toggleChat,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 2. LAUNCHER
// ============================================================

class _CopilotLauncher extends StatelessWidget {
  const _CopilotLauncher({
    super.key,
    required this.onTap,
    required this.hasActiveChat,
  });

  final VoidCallback onTap;
  final bool hasActiveChat;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.royalBlue],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gold, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .20),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.navy,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Faithi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  hasActiveChat ? 'Continue your chat' : 'Ask your salon copilot',
                  style: const TextStyle(
                    color: Color(0xFFFFD761),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 3. FULL PAGE
// ============================================================

class AIChatPage extends StatelessWidget {
  const AIChatPage({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Faithi'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: FaithAICopilotPanel(navigatorKey: navigatorKey),
        ),
      ),
    );
  }
}

// ============================================================
// 4. MAIN PANEL
// ============================================================

class FaithAICopilotPanel extends StatefulWidget {
  const FaithAICopilotPanel({
    super.key,
    this.onClose,
    this.onMinimize,
    this.navigatorKey,
  });

  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<FaithAICopilotPanel> createState() => _FaithAICopilotPanelState();
}

class _FaithAICopilotPanelState extends State<FaithAICopilotPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FaithCopilotController _controller;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechReady = false;
  bool _isListening = false;
  String? _speechError;

  @override
  void initState() {
    super.initState();
    _controller = FaithCopilotController.instance;
    _controller.addListener(_onControllerChanged);
    _initializeSpeech();

    if (_controller.services.isEmpty) {
      _controller.loadSalonData();
    }

    _controller.initializeVoice();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _speech.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() => _scrollToBottom();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 400,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _speechError = error.errorMsg;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _speechReady = available;
        _speechError = available ? null : 'Voice input is not available.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechReady = false;
        _speechError = 'Voice input could not be initialized.';
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_controller.isLoading) return;

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    await _controller.stopSpeaking();

    if (!_speechReady) {
      await _initializeSpeech();
      if (!_speechReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_speechError ?? 'Microphone unavailable.')),
        );
        return;
      }
    }

    setState(() {
      _isListening = true;
      _speechError = null;
    });

    await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      onResult: (result) {
        if (!mounted) return;
        final words = _removeDuplicatedSpeech(result.recognizedWords.trim());

        if (words.isNotEmpty) {
          _textController.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
        }

        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  String _removeDuplicatedSpeech(String input) {
    if (input.length < 2) return input;
    if (input.length.isEven) {
      final half = input.length ~/ 2;
      final first = input.substring(0, half);
      final second = input.substring(half);
      if (first.toLowerCase() == second.toLowerCase()) return first;
    }
    return input;
  }

  void _sendMessage([String? preset]) {
    final text = (preset ?? _textController.text).trim();
    if (text.isEmpty || _controller.isLoading) return;
    _textController.clear();
    _controller.sendMessage(text);
  }

  Future<void> _openBooking() async {
    final service = _controller.getSuggestedService();

    if (service == null) {
      _controller.addSystemMessage(
        'Tell me which hairstyle you want first. I can also recommend one for you.',
      );
      return;
    }

    final route = MaterialPageRoute(
      builder: (_) => BookingPage(service: service),
    );

    final globalNavigator = widget.navigatorKey?.currentState;
    if (globalNavigator != null) {
      await globalNavigator.push(route);
    } else if (mounted) {
      await Navigator.of(context).push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = math.min(430.0, math.max(280.0, screen.width - 24));
    final height = math.min(650.0, math.max(320.0, screen.height - 32));

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .24),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildQuickActions(),
              const Divider(height: 1, color: AppColors.borderLight),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: _controller.messages.length +
                      (_controller.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_controller.isLoading &&
                        index == _controller.messages.length) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(message: _controller.messages[index]);
                  },
                ),
              ),
              if (_controller.showBookingButton && !_controller.isLoading)
                _buildBookingButton(),
              if (_isListening) _buildListeningBanner(),
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.deepBlue,
            AppColors.royalBlue,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.navy,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FAITHI AI COPILOT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                Text(
                  _controller.isLoadingData
                      ? 'Loading live salon info...'
                      : 'Styles • prices • colors • availability',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFD761),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip:
                _controller.voiceEnabled ? 'Turn voice off' : 'Turn voice on',
            onPressed: _controller.toggleVoice,
            icon: Icon(
              _controller.voiceEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _controller.voiceEnabled
                  ? const Color(0xFFFFD761)
                  : Colors.white70,
              size: 21,
            ),
          ),
          IconButton(
            tooltip: 'Refresh salon data',
            onPressed:
                _controller.isLoadingData ? null : _controller.loadSalonData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          if (widget.onMinimize != null)
            IconButton(
              tooltip: 'Minimize',
              onPressed: widget.onMinimize,
              icon: const Icon(
                Icons.remove_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Close',
              onPressed: widget.onClose,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _QuickChip(
            label: 'Choose for me',
            icon: Icons.auto_awesome_rounded,
            onTap: () => _sendMessage(
              'Recommend a hairstyle for me using the live Faith Hairstyle services.',
            ),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Under my budget',
            icon: Icons.savings_outlined,
            onTap: () =>
                _sendMessage('Help me find a hairstyle within my budget.'),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Colors',
            icon: Icons.palette_outlined,
            onTap: () => _sendMessage('Show me the available hair colors.'),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Open times',
            icon: Icons.schedule_rounded,
            onTap: () =>
                _sendMessage('Show me the next available appointment times.'),
            isLoading: _controller.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    final name = _controller.lastSuggestedServiceName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _openBooking,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(
            name == null ? 'OPEN BOOKING' : 'BOOK ${name.toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListeningBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: const Row(
        children: [
          _VoicePulse(),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Listening... speak naturally.',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_controller.isLoading,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask Faithi anything...',
                filled: true,
                fillColor: AppColors.pageBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: AppColors.gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton.filled(
              tooltip: _isListening ? 'Stop listening' : 'Voice input',
              onPressed: _controller.isLoading ? null : _toggleListening,
              style: IconButton.styleFrom(
                backgroundColor:
                    _isListening ? const Color(0xFFD84A4A) : Colors.white,
                foregroundColor:
                    _isListening ? Colors.white : AppColors.deepGold,
                side: const BorderSide(color: AppColors.borderGold),
              ),
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              onPressed: _controller.isLoading ? null : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 5. MESSAGE UI
// ============================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(13),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AppColors.gold, Color(0xFFF0BC27)],
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.deepGold,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  isUser ? 'You' : 'Faithi',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            _MarkdownText(text: message.text),
            if (!isUser && message.serviceImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ServiceRecommendationImages(images: message.serviceImages),
            ],
            if (!isUser && message.colors.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ColorResults(colors: message.colors),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 6. SERVICE IMAGES
// ============================================================

class _ServiceRecommendationImages extends StatelessWidget {
  const _ServiceRecommendationImages({required this.images});

  final List<ServiceImageAttachment> images;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < images.length; i++) ...[
          _ServiceImageCard(image: images[i]),
          if (i != images.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ServiceImageCard extends StatelessWidget {
  const _ServiceImageCard({required this.image});

  final ServiceImageAttachment image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              image.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                );
              },
              errorBuilder: (_, __, ___) {
                return Container(
                  alignment: Alignment.center,
                  color: AppColors.pageBackground,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.muted,
                        size: 34,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Style image unavailable',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.serviceName,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                if (image.price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Starting at ${image.price}',
                      style: const TextStyle(
                        color: AppColors.deepGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 7. COLORS
// ============================================================

class _ColorResults extends StatelessWidget {
  const _ColorResults({required this.colors});

  final List<HairColorResult> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: colors.map((color) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGold),
          ),
          child: Text(
            '${color.code} • ${color.name}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// 8. MARKDOWN-LIKE TEXT
// ============================================================

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final split = text.split('**');

    for (int i = 0; i < split.length; i++) {
      if (split[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: split[i],
          style: TextStyle(
            fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
            color: AppColors.navy,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

// ============================================================
// 9. QUICK CHIP
// ============================================================

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: AppColors.deepGold),
      label: Text(label),
      onPressed: isLoading ? null : onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.borderGold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelStyle: const TextStyle(
        color: AppColors.navy,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ============================================================
// 10. VOICE PULSE
// ============================================================

class _VoicePulse extends StatefulWidget {
  const _VoicePulse();

  @override
  State<_VoicePulse> createState() => _VoicePulseState();
}

class _VoicePulseState extends State<_VoicePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: .85, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFFD84A4A),
        child: Icon(Icons.mic_rounded, size: 14, color: Colors.white),
      ),
    );
  }
}

// ============================================================
// 11. TYPING INDICATOR
// ============================================================

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * .2;
                final progress =
                    (_controller.value - delay).clamp(0.0, 1.0);
                final offset = math.sin(progress * math.pi * 2) * -4;

                return Transform.translate(
                  offset: Offset(0, offset < 0 ? offset : 0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ============================================================
// 12. CONTROLLER — ONE PRIMARY MODEL + NATURAL VOICE
// ============================================================

class FaithCopilotController extends ChangeNotifier {
  static final FaithCopilotController instance =
      FaithCopilotController._internal();

  FaithCopilotController._internal() {
    _messages.add(
      const ChatMessage(
        text:
            'Hi! I’m Faithi, your Faith Hairstyle salon copilot. '
            'Tell me the look you want, your budget, your preferred color, '
            'or when you want to come in.',
        isUser: false,
      ),
    );
  }

  // CURRENT Railway production backend.
  static const String _apiBase =
      'https://theyoungshallgrow-api-production.up.railway.app';

  static const String _aiEndpoint = '$_apiBase/chat';

  // ONE MODEL ONLY. The backend should honor this model policy.
  static const String _primaryModel =
      'meta-llama/Llama-3.1-8B-Instruct';

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterTts _tts = FlutterTts();
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasChatHistory => _messages.length > 1;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingData = false;
  bool get isLoadingData => _isLoadingData;

  bool _showBookingButton = false;
  bool get showBookingButton => _showBookingButton;

  bool _voiceEnabled = true;
  bool get voiceEnabled => _voiceEnabled;

  bool _voiceInitialized = false;

  final CustomerPreferences preferences = CustomerPreferences();

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> hairColors = [];

  String? lastSuggestedServiceName;
  String? lastSuggestedServiceId;
  DateTime? _lastSendAt;

  // ==========================================================
  // TTS / NATURAL ENGLISH VOICE
  // ==========================================================

  Future<void> initializeVoice() async {
    if (_voiceInitialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(.46);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      // Makes long answers sound more continuous when supported.
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      try {
        final dynamic rawVoices = await _tts.getVoices;

        if (rawVoices is List && rawVoices.isNotEmpty) {
          final voices = rawVoices
              .whereType<Map>()
              .map((voice) => Map<dynamic, dynamic>.from(voice))
              .where((voice) {
                final locale =
                    (voice['locale'] ?? '').toString().toLowerCase();
                return locale.startsWith('en');
              })
              .toList();

          voices.sort((a, b) => _voiceScore(b).compareTo(_voiceScore(a)));

          if (voices.isNotEmpty) {
            final selected = voices.first;
            final name = (selected['name'] ?? '').toString();
            final locale = (selected['locale'] ?? 'en-US').toString();

            if (name.isNotEmpty) {
              await _tts.setVoice({
                'name': name,
                'locale': locale,
              });
            }
          }
        }
      } catch (_) {
        // If the platform does not expose voices, use its normal English voice.
      }

      _voiceInitialized = true;
    } catch (_) {
      _voiceInitialized = false;
    }
  }

  int _voiceScore(Map<dynamic, dynamic> voice) {
    final name = (voice['name'] ?? '').toString().toLowerCase();
    final locale = (voice['locale'] ?? '').toString().toLowerCase();

    var score = 0;

    if (locale == 'en-us' || locale == 'en_us') score += 60;
    if (locale.startsWith('en-us') || locale.startsWith('en_us')) score += 35;
    if (locale.startsWith('en')) score += 15;

    // Prefer names commonly used by high-quality natural/neural voices.
    for (final word in [
      'natural',
      'neural',
      'premium',
      'enhanced',
      'online',
      'wavenet',
      'jenny',
      'aria',
      'ava',
      'samantha',
      'zira',
      'susan',
      'victoria',
      'karen',
      'moira',
      'female',
    ]) {
      if (name.contains(word)) score += 20;
    }

    // De-prioritize obviously basic/legacy synthesizers when alternatives exist.
    for (final word in ['compact', 'legacy', 'espeak']) {
      if (name.contains(word)) score -= 30;
    }

    return score;
  }

  Future<void> toggleVoice() async {
    _voiceEnabled = !_voiceEnabled;

    if (!_voiceEnabled) {
      await _tts.stop();
    } else {
      await initializeVoice();
    }

    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;

    final cleaned = _textForSpeech(text);
    if (cleaned.isEmpty) return;

    try {
      await initializeVoice();
      await _tts.stop();

      for (final chunk in _speechChunks(cleaned)) {
        if (!_voiceEnabled) break;
        await _tts.speak(chunk);
      }
    } catch (_) {}
  }

  List<String> _speechChunks(String text, {int maxChars = 1200}) {
    if (text.length <= maxChars) return [text];

    final words = text.split(RegExp(r'\s+'));
    final chunks = <String>[];
    var current = StringBuffer();

    for (final word in words) {
      if (word.isEmpty) continue;

      if (current.isNotEmpty && current.length + word.length + 1 > maxChars) {
        chunks.add(current.toString().trim());
        current = StringBuffer();
      }

      if (current.isNotEmpty) current.write(' ');
      current.write(word);
    }

    if (current.isNotEmpty) {
      chunks.add(current.toString().trim());
    }

    return chunks.where((chunk) => chunk.isNotEmpty).toList();
  }

  String _textForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAllMapped(
          RegExp(r'`([^`]*)`'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'https?:\/\/\S+', caseSensitive: false), '')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]*\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^[•*\-]\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ==========================================================
  // PUBLIC SALON DATA FOR UI
  // ==========================================================

  Future<void> loadSalonData() async {
    _isLoadingData = true;
    notifyListeners();

    try {
      final rows = await _supabase
          .from('services')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);

      services = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      services = [];
    }

    try {
      final rows = await _supabase
          .from('hair_colors')
          .select()
          .eq('is_active', true)
          .order('code', ascending: true);

      hairColors = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      hairColors = [];
    }

    _isLoadingData = false;
    notifyListeners();
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty || _isLoading) return;

    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!).inMilliseconds < 450) {
      return;
    }
    _lastSendAt = now;

    await stopSpeaking();
    preferences.extractAndRemember(cleanText);

    _messages.add(ChatMessage(text: cleanText, isUser: true));

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _fetchAIResponse(cleanText);
      final reply = _removeRepeatedGreeting(result.reply);

      _processAIResponse(
        userText: cleanText,
        reply: reply,
        structuredRows: result.rows,
        meta: result.meta,
      );

      await _speak(reply);
    } catch (error) {
      const message =
          'I could not reach the Faithi AI service right now. Please try again.';

      _messages.add(
        const ChatMessage(text: message, isUser: false),
      );

      await _speak(message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // API
  // ==========================================================

  Future<FaithiApiResult> _fetchAIResponse(String customerMessage) async {
    final historySource = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];

    final recentHistory = historySource.length > 12
        ? historySource.sublist(historySource.length - 12)
        : historySource;

    final history = recentHistory
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();

    final body = {
      'message': customerMessage,
      'history': history,

      // ONE PRIMARY MODEL ONLY.
      'model': _primaryModel,
      'primary_model': _primaryModel,
      'single_model_only': true,

      'domain': 'hair_salon',
      'page': 'ai_chat',
      'safe_mode': true,
      'advanced_mode': true,
      'context': {
        'app': 'faith_hairstyle',
        'assistant': 'faithi',
        'backend_generation': 'v4.4+',
        'model_policy': {
          'primary_model': _primaryModel,
          'single_model_only': true,
        },
        'response_style': {
          'natural_conversation': true,
          'chatgpt_like': true,
          'context_aware': true,
          'warm_and_professional': true,
          'answer_directly': true,
          'avoid_repeated_greetings': true,
          'avoid_robotic_language': true,
          'avoid_unnecessary_disclaimers': true,
          'ask_follow_up_only_when_needed': true,
          'use_conversation_history': true,
          'use_live_salon_data_for_business_facts': true,
          'do_not_invent_prices_services_colors_or_availability': true,
        },
        'customer_preferences': preferences.toMap(),
        'frontend_capabilities': {
          'service_images': true,
          'booking_navigation': true,
          'voice_input': true,
          'voice_output': true,
        },
      },
    };

    final response = await http
        .post(
          Uri.parse(_aiEndpoint),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Faithi server returned ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid Faithi response.');
    }

    final reply = (decoded['reply'] ?? '').toString().trim();
    if (reply.isEmpty) {
      throw Exception('Faithi returned no reply.');
    }

    final rows = _extractDataframeRows(decoded['dataframe']);

    final meta = decoded['meta'] is Map
        ? Map<String, dynamic>.from(decoded['meta'])
        : <String, dynamic>{};

    return FaithiApiResult(reply: reply, rows: rows, meta: meta);
  }

  // ==========================================================
  // DATAFRAME PARSER
  // ==========================================================

  List<Map<String, dynamic>> _extractDataframeRows(dynamic dataframe) {
    if (dataframe == null) return [];

    if (dataframe is Map) {
      final rawRows = dataframe['rows'];

      if (rawRows is List) {
        return rawRows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }

      final columns = dataframe['columns'];
      final data = dataframe['data'];

      if (columns is List && data is List) {
        final names = columns.map((e) => e.toString()).toList();
        final output = <Map<String, dynamic>>[];

        for (final raw in data) {
          if (raw is! List) continue;
          final row = <String, dynamic>{};

          for (int i = 0; i < names.length && i < raw.length; i++) {
            row[names[i]] = raw[i];
          }

          output.add(row);
        }

        return output;
      }

      if (dataframe.containsKey('name') ||
          dataframe.containsKey('image_url')) {
        return [Map<String, dynamic>.from(dataframe)];
      }
    }

    if (dataframe is List) {
      return dataframe
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    return [];
  }

  // ==========================================================
  // PROCESS BACKEND RESULT
  // ==========================================================

  void _processAIResponse({
    required String userText,
    required String reply,
    required List<Map<String, dynamic>> structuredRows,
    required Map<String, dynamic> meta,
  }) {
    final serviceMatches = <Map<String, dynamic>>[];
    final colorMatches = <HairColorResult>[];
    final seenServices = <String>{};
    final seenColors = <String>{};

    for (final row in structuredRows) {
      final table =
          (row['_table'] ?? row['source_table'] ?? '').toString().toLowerCase();

      final name = (row['name'] ?? '').toString().trim();
      final imageUrl = (row['image_url'] ?? '').toString().trim();
      final code = (row['code'] ?? row['detail'] ?? '').toString().trim();

      final looksLikeColor = table.contains('color') ||
          (code.isNotEmpty &&
              imageUrl.isEmpty &&
              _findLocalColor(code, name) != null);

      if (looksLikeColor && name.isNotEmpty) {
        final key = '$code|$name'.toLowerCase();

        if (seenColors.add(key)) {
          colorMatches.add(HairColorResult(code: code, name: name));
        }
        continue;
      }

      final localService = _matchStructuredService(row);

      if (localService != null) {
        final key = localService['id']?.toString() ??
            localService['name']?.toString() ??
            '';

        if (seenServices.add(key)) {
          serviceMatches.add(localService);
        }
      }
    }

    if (serviceMatches.isEmpty) {
      serviceMatches.addAll(_findServicesFromText(reply));
    }

    if (serviceMatches.isEmpty) {
      serviceMatches.addAll(_findServicesFromText(userText));
    }

    if (colorMatches.isEmpty && _isColorIntent(userText)) {
      final specific = _findColorsFromText('$userText $reply');

      if (specific.isNotEmpty) {
        colorMatches.addAll(specific);
      } else if (_asksToShowColors(userText)) {
        colorMatches.addAll(
          hairColors.take(32).map(
                (row) => HairColorResult(
                  code: (row['code'] ?? '').toString(),
                  name: (row['name'] ?? '').toString(),
                ),
              ),
        );
      }
    }

    final images = <ServiceImageAttachment>[];

    for (final service in serviceMatches) {
      final imageUrl = (service['image_url'] ?? '').toString().trim();
      if (!_isHttpUrl(imageUrl)) continue;

      images.add(
        ServiceImageAttachment(
          serviceId: service['id']?.toString(),
          serviceName: (service['name'] ?? 'Hairstyle').toString(),
          url: imageUrl,
          price: _money(service['price']),
        ),
      );

      if (images.length >= 3) break;
    }

    _messages.add(
      ChatMessage(
        text: reply,
        isUser: false,
        serviceImages: images,
        colors: colorMatches,
      ),
    );

    if (serviceMatches.isNotEmpty) {
      final selected = serviceMatches.first;
      lastSuggestedServiceName = selected['name']?.toString();
      lastSuggestedServiceId = selected['id']?.toString();
    }

    final intent = (meta['intent'] ?? '').toString().toLowerCase();

    if (_isBookingIntent(userText) ||
        _isBookingIntent(reply) ||
        intent == 'booking' ||
        serviceMatches.isNotEmpty) {
      _showBookingButton =
          serviceMatches.isNotEmpty || getSuggestedService() != null;
    }
  }

  Map<String, dynamic>? _matchStructuredService(Map<String, dynamic> row) {
    final id = (row['id'] ?? row['service_id'] ?? '').toString();

    if (id.isNotEmpty) {
      for (final service in services) {
        if (service['id']?.toString() == id) return service;
      }
    }

    final name = (row['name'] ?? row['service_name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (name.isNotEmpty) {
      for (final service in services) {
        final localName =
            (service['name'] ?? '').toString().trim().toLowerCase();
        if (localName == name) return service;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _findServicesFromText(String text) {
    final lower = text.toLowerCase();
    final matches = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final service in services) {
      final name = (service['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      if (lower.contains(name.toLowerCase())) {
        final id = service['id']?.toString() ?? name.toLowerCase();
        if (seen.add(id)) matches.add(service);
      }
    }

    return matches.take(5).toList();
  }

  bool _isColorIntent(String text) {
    final lower = text.toLowerCase();

    return lower.contains('color') ||
        lower.contains('colour') ||
        lower.contains('burgundy') ||
        lower.contains('blonde') ||
        lower.contains('auburn') ||
        lower.contains('copper') ||
        lower.contains('black') ||
        lower.contains('brown') ||
        lower.contains('purple') ||
        lower.contains('pink') ||
        lower.contains('blue') ||
        lower.contains('green') ||
        lower.contains('mahogany') ||
        RegExp(
          r'\b(?:1b|99j|613|350|425|530|t1b\/\w+)\b',
          caseSensitive: false,
        ).hasMatch(lower);
  }

  bool _asksToShowColors(String text) {
    final lower = text.toLowerCase();

    return lower.contains('show color') ||
        lower.contains('show me color') ||
        lower.contains('available color') ||
        lower.contains('what color') ||
        lower.trim() == 'colors' ||
        lower.trim() == 'colours';
  }

  List<HairColorResult> _findColorsFromText(String text) {
    final lower = text.toLowerCase();
    final output = <HairColorResult>[];
    final seen = <String>{};

    for (final row in hairColors) {
      final code = (row['code'] ?? '').toString().trim();
      final name = (row['name'] ?? '').toString().trim();

      if (code.isEmpty && name.isEmpty) continue;

      final codeMatch = code.isNotEmpty &&
          RegExp(
            r'(^|[^a-z0-9])' +
                RegExp.escape(code.toLowerCase()) +
                r'([^a-z0-9]|$)',
          ).hasMatch(lower);

      final nameMatch =
          name.isNotEmpty && lower.contains(name.toLowerCase());

      if (codeMatch || nameMatch) {
        final key = '$code|$name'.toLowerCase();

        if (seen.add(key)) {
          output.add(HairColorResult(code: code, name: name));
        }
      }
    }

    return output;
  }

  Map<String, dynamic>? _findLocalColor(String code, String name) {
    for (final row in hairColors) {
      final localCode = (row['code'] ?? '').toString().trim();
      final localName = (row['name'] ?? '').toString().trim();

      if (code.isNotEmpty &&
          localCode.toLowerCase() == code.toLowerCase()) {
        return row;
      }

      if (name.isNotEmpty &&
          localName.toLowerCase() == name.toLowerCase()) {
        return row;
      }
    }

    return null;
  }

  Map<String, dynamic>? getSuggestedService() {
    if (lastSuggestedServiceId != null) {
      for (final service in services) {
        if (service['id']?.toString() == lastSuggestedServiceId) {
          return service;
        }
      }
    }

    if (lastSuggestedServiceName != null) {
      for (final service in services) {
        if ((service['name'] ?? '').toString().toLowerCase() ==
            lastSuggestedServiceName!.toLowerCase()) {
          return service;
        }
      }
    }

    return null;
  }

  bool _isBookingIntent(String text) {
    final lower = text.toLowerCase();

    return lower.contains('book') ||
        lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('reserve') ||
        lower.contains('availability') ||
        lower.contains('available time') ||
        lower.contains('open time');
  }


  void addSystemMessage(String text) {
    _messages.add(ChatMessage(text: text, isUser: false));
    notifyListeners();
    _speak(text);
  }

  String _removeRepeatedGreeting(String text) {
    var cleaned = text.trimLeft();

    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:good\s+(?:morning|afternoon|evening)|hello(?:\s+again)?|hi(?:\s+again)?)[!,.:\-\s]*',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.replaceFirst(
      RegExp(
        r"^(?:i['’]?m|i am)\s+(?:faith\s+ai|faithi)(?:,\s*your\s+salon\s+copilot)?[!,.:\-\s]*",
        caseSensitive: false,
      ),
      '',
    );

    if (cleaned.trim().isEmpty) return text.trim();
    return cleaned.trimLeft();
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String? _money(dynamic value) {
    if (value == null) return null;

    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();

    if (parsed == parsed.roundToDouble()) {
      return '\$${parsed.toStringAsFixed(0)}';
    }

    return '\$${parsed.toStringAsFixed(2)}';
  }
}

// ============================================================
// 13. API RESULT
// ============================================================

class FaithiApiResult {
  const FaithiApiResult({
    required this.reply,
    required this.rows,
    required this.meta,
  });

  final String reply;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> meta;
}

// ============================================================
// 14. MESSAGE DATA
// ============================================================

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.serviceImages = const [],
    this.colors = const [],
  });

  final String text;
  final bool isUser;
  final List<ServiceImageAttachment> serviceImages;
  final List<HairColorResult> colors;
}

// ============================================================
// 15. SERVICE IMAGE
// ============================================================

class ServiceImageAttachment {
  const ServiceImageAttachment({
    required this.serviceName,
    required this.url,
    this.serviceId,
    this.price,
  });

  final String? serviceId;
  final String serviceName;
  final String url;
  final String? price;
}

// ============================================================
// 16. HAIR COLOR
// ============================================================

class HairColorResult {
  const HairColorResult({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}

// ============================================================
// 17. CUSTOMER PREFERENCES
// ============================================================

class CustomerPreferences {
  String? budget;
  String? length;
  String? size;
  String? color;
  String? occasion;
  String? datePreference;

  void extractAndRemember(String text) {
    final lower = text.toLowerCase();

    final budgetMatch = RegExp(
      r'(?:\$\s*|budget(?:\s+is|\s+of|\s+around|\s+about|\s+under)?\s*\$?)(\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);

    if (budgetMatch != null) {
      budget = '\$${budgetMatch.group(1)}';
    }

    for (final value in [
      'shoulder',
      'midback',
      'mid back',
      'waist',
      'top butt',
      'mid butt',
      'under butt',
      'butt length',
    ]) {
      if (lower.contains(value)) length = value;
    }

    for (final value in [
      'jumbo',
      'large',
      'small medium',
      'semi-medium',
      'semi medium',
      'medium',
      'small',
    ]) {
      if (lower.contains(value)) size = value;
    }

    final colorMatch = RegExp(
      r'(?:color|colour)\s*(?:#|number|no\.?|code)?\s*([a-z0-9\/]+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (colorMatch != null) {
      color = colorMatch.group(1);
    }

    for (final value in [
      'birthday',
      'wedding',
      'vacation',
      'work',
      'school',
      'party',
      'photoshoot',
      'photo shoot',
    ]) {
      if (lower.contains(value)) occasion = value;
    }

    final dateWords = [
      'today',
      'tomorrow',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
      'morning',
      'afternoon',
      'evening',
    ];

    final mentioned = dateWords.where(lower.contains).toList();

    if (mentioned.isNotEmpty) {
      datePreference = mentioned.join(', ');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (budget != null) 'budget': budget,
      if (length != null) 'length': length,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (occasion != null) 'occasion': occasion,
      if (datePreference != null) 'date_time_preference': datePreference,
    };
  }
}

// ============================================================
// 18. COLORS
// ============================================================

class AppColors {
  static const Color navy = Color(0xFF071A42);
  static const Color deepBlue = Color(0xFF0A2D6E);
  static const Color royalBlue = Color(0xFF0754AD);
  static const Color gold = Color(0xFFE4AD16);
  static const Color deepGold = Color(0xFF9A6800);
  static const Color pageBackground = Color(0xFFF6F8FC);
  static const Color borderGold = Color(0xFFD8B649);
  static const Color borderLight = Color(0xFFE6EAF2);
  static const Color muted = Color(0xFF667085);
}
