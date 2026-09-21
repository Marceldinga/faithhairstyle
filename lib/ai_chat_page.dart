import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'booking_page.dart';

// ============================================================
// FAITH AI COPILOT
// ============================================================
// 1. Salon-first routing.
// 2. Common hairstyle typo correction.
// 3. "briad" -> "braid".
// 4. Blocks accidental statistics responses.
// 5. Preserves original customer text in the UI.
// 6. Sends Faith Hairstyle domain metadata to backend.
// 7. Uses live Supabase salon services.
// 8. Uses only real service image_url values.
// 9. Keeps booking integration.
// 10. Keeps speech input.
// 11. Keeps local salon knowledge retrieval.
// 12. Uses TheYoungShallGrow Railway backend.
// ============================================================

// ==========================================
// 1. SHELL & LAUNCHER
// ==========================================

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

  void _toggleChat() {
    if (_isOpen) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 600;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        widget.child,

        if (_isOpen && isPhone)
          Positioned.fill(
            child: Material(
              color: AppColors.pageBackground,
              child: SafeArea(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: FaithAICopilotPanel(
                    key: const ValueKey('mobile-panel'),
                    navigatorKey: widget.navigatorKey,
                    onClose: _toggleChat,
                    onMinimize: _toggleChat,
                  ),
                ),
              ),
            ),
          )
        else
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
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _CopilotLauncher(
                    key: const ValueKey('launcher'),
                    hasActiveChat:
                        FaithCopilotController.instance.hasChatHistory,
                    onTap: _toggleChat,
                  ),
                ),
              ),
            ),
          ),

        if (_isOpen && !isPhone)
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: FaithAICopilotPanel(
                  key: const ValueKey('desktop-panel'),
                  navigatorKey: widget.navigatorKey,
                  onClose: _toggleChat,
                  onMinimize: _toggleChat,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.navy,
              AppColors.royalBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.gold,
            width: 1.4,
          ),
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
                  'Faith AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  hasActiveChat
                      ? 'Continue your chat'
                      : 'Ask your salon copilot',
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

// ==========================================
// FULL PAGE
// ==========================================

class AIChatPage extends StatelessWidget {
  const AIChatPage({
    super.key,
    this.navigatorKey,
  });

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: isPhone
          ? null
          : AppBar(
              title: const Text('Faith AI'),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
      body: SafeArea(
        child: FaithAICopilotPanel(
          navigatorKey: navigatorKey,
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANEL
// ==========================================

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
    _controller.addListener(_scrollToBottom);

    _initializeSpeech();

    if (_controller.services.isEmpty) {
      _controller.loadSalonData();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollToBottom);
    _speech.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 300,
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
        _speechError = available
            ? null
            : 'Voice input is not available on this device or browser.';
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

    if (!_speechReady) {
      await _initializeSpeech();

      if (!_speechReady) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _speechError ?? 'Microphone access is unavailable.',
            ),
          ),
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
      partialResults: false,
      cancelOnError: true,
      onResult: (result) {
        if (!mounted) return;

        final words = _cleanSpeechText(result.recognizedWords);

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

  String _cleanSpeechText(String raw) {
    var text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (text.isEmpty) return text;

    for (var pass = 0; pass < 3; pass++) {
      if (text.length < 6 || !text.length.isEven) break;

      final half = text.length ~/ 2;
      final first = text.substring(0, half);
      final second = text.substring(half);

      if (first.toLowerCase() != second.toLowerCase()) break;

      text = first.trim();
    }

    final tokens = text.split(' ');

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      final match = RegExp(
        r"^([A-Za-z][A-Za-z'’\-]*)([.,!?;:]*)$",
      ).firstMatch(token);

      if (match == null) continue;

      final core = match.group(1)!;
      final punctuation = match.group(2) ?? '';

      if (core.length < 6 || !core.length.isEven) continue;

      final half = core.length ~/ 2;
      final first = core.substring(0, half);
      final second = core.substring(half);

      if (first.length >= 3 &&
          first.toLowerCase() == second.toLowerCase()) {
        tokens[i] = '$first$punctuation';
      }
    }

    var words = tokens;
    var changed = true;

    while (changed && words.length >= 2) {
      changed = false;

      final maxBlock = math.min(4, words.length ~/ 2);

      for (var block = 1; block <= maxBlock && !changed; block++) {
        for (var start = 0;
            start + (block * 2) <= words.length;
            start++) {
          var same = true;

          for (var j = 0; j < block; j++) {
            if (words[start + j].toLowerCase() !=
                words[start + block + j].toLowerCase()) {
              same = false;
              break;
            }
          }

          if (same) {
            words.removeRange(
              start + block,
              start + (block * 2),
            );

            changed = true;
            break;
          }
        }
      }
    }

    return words.join(' ').trim();
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
        'Before I open booking, tell me which hairstyle you want. I can also recommend one based on your budget.',
      );
      return;
    }

    final route = MaterialPageRoute(
      builder: (_) => BookingPage(service: service),
    );

    final globalNav = widget.navigatorKey?.currentState;

    if (globalNav != null) {
      await globalNav.push(route);
    } else if (mounted) {
      await Navigator.maybeOf(context)?.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screen.width;

        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screen.height;

        final width = isPhone
            ? availableWidth
            : math.min(
                430.0,
                math.max(280.0, availableWidth),
              );

        final height = isPhone
            ? availableHeight
            : math.min(
                650.0,
                math.max(320.0, availableHeight),
              );

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Container(
              width: width,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(isPhone ? 0 : 24),
                border: isPhone
                    ? null
                    : Border.all(
                        color: AppColors.gold,
                        width: 1.3,
                      ),
                boxShadow: isPhone
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .24),
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  _buildHeader(compact: isPhone),
                  _buildQuickActions(),
                  const Divider(
                    height: 1,
                    color: AppColors.borderLight,
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      itemCount: _controller.messages.length +
                          (_controller.isLoading ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (_controller.isLoading &&
                            index == _controller.messages.length) {
                          return const _TypingIndicator();
                        }

                        return _MessageBubble(
                          message: _controller.messages[index],
                        );
                      },
                    ),
                  ),
                  if (_controller.showBookingButton &&
                      !_controller.isLoading)
                    _buildBookingButton(),
                  if (_isListening) _buildListeningBanner(),
                  _buildInputArea(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader({required bool compact}) {
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
                  'FAITH AI COPILOT',
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
            tooltip: 'Refresh',
            onPressed:
                _controller.isLoadingData ? null : _controller.loadSalonData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          if (!compact && widget.onMinimize != null)
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
              'Help me choose the best hairstyle. Ask only one useful question if you still need information.',
            ),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Under my budget',
            icon: Icons.savings_outlined,
            onTap: () => _sendMessage(
              'Help me find hairstyles that fit my budget. Ask my budget if I have not told you yet.',
            ),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Open times',
            icon: Icons.schedule_rounded,
            onTap: () => _sendMessage(
              'Show me the next available appointment times.',
            ),
            isLoading: _controller.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    final serviceName = _controller.lastSuggestedServiceName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _openBooking,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(
            serviceName == null
                ? 'OPEN BOOKING'
                : 'BOOK ${serviceName.toUpperCase()}',
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: const ValueKey('voice-listening'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7DB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGold),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VoicePulse(),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Listening... speak naturally. Tap the microphone again to stop.',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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
                hintText: 'Ask Faith AI anything...',
                hintStyle: const TextStyle(fontSize: 12.5),
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
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                    width: 1.5,
                  ),
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
                size: 22,
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
              child: const Icon(
                Icons.send_rounded,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. MESSAGE UI
// ==========================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
  });

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
                  colors: [
                    AppColors.gold,
                    Color(0xFFF0BC27),
                  ],
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
              : Border.all(
                  color: AppColors.borderLight,
                ),
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
                  isUser ? 'You' : 'Faith AI',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            _ParsedMessageContent(text: message.text),
            if (!isUser && message.serviceImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ServiceRecommendationImages(
                images: message.serviceImages,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceRecommendationImages extends StatelessWidget {
  const _ServiceRecommendationImages({
    required this.images,
  });

  final List<ServiceImageAttachment> images;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
  const _ServiceImageCard({
    required this.image,
  });

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
              width: double.infinity,
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
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.pageBackground,
                alignment: Alignment.center,
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
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_camera_rounded,
                  size: 16,
                  color: AppColors.deepGold,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    image.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
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

// ==========================================
// MARKDOWN + IMAGE PARSER
// ==========================================

class _ParsedMessageContent extends StatelessWidget {
  const _ParsedMessageContent({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');

    final matches = imageRegex.allMatches(text);

    if (matches.isEmpty) {
      return _MarkdownText(text: text);
    }

    final children = <Widget>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        final textPart = text.substring(lastMatchEnd, match.start).trim();

        if (textPart.isNotEmpty) {
          children.add(_MarkdownText(text: textPart));
          children.add(const SizedBox(height: 10));
        }
      }

      final altText = match.group(1) ?? '';
      final imageUrl = match.group(2) ?? '';

      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  width: double.infinity,
                  color: AppColors.pageBackground,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.muted,
                        size: 32,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (altText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                altText,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );

      children.add(const SizedBox(height: 10));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      final textPart = text.substring(lastMatchEnd).trim();

      if (textPart.isNotEmpty) {
        children.add(_MarkdownText(text: textPart));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final split = text.split('**');

    for (int i = 0; i < split.length; i++) {
      if (split[i].isEmpty) continue;

      final isBold = i % 2 != 0;

      spans.add(
        TextSpan(
          text: split[i],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.navy,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}

// ==========================================
// QUICK CHIP
// ==========================================

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
      avatar: Icon(
        icon,
        size: 17,
        color: AppColors.deepGold,
      ),
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

// ==========================================
// VOICE ANIMATION
// ==========================================

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

    _scale = Tween<double>(
      begin: .85,
      end: 1.18,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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
        child: Icon(
          Icons.mic_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ==========================================
// TYPING INDICATOR
// ==========================================

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delay = index * .2;

                  final progress =
                      (_controller.value - delay).clamp(0.0, 1.0);

                  final offset =
                      math.sin(progress * math.pi * 2) * -4;

                  return Transform.translate(
                    offset: Offset(
                      0,
                      offset < 0 ? offset : 0,
                    ),
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
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 4. FAITH AI CONTROLLER
// ============================================================

class FaithCopilotController extends ChangeNotifier {
  static final FaithCopilotController instance =
      FaithCopilotController._internal();

  FaithCopilotController._internal() {
    _messages.add(
      const ChatMessage(
        text:
            'Hi! I’m Faith AI, your salon copilot. Tell me the look you want, your budget, or when you want to come in — I’ll help you narrow it down and get ready to book.',
        isUser: false,
      ),
    );
  }

  final _supabase = Supabase.instance.client;

  // ============================================================
  // NEW BACKEND
  // ============================================================

  static const String _aiEndpoint =
      'https://theyoungshallgrow-api-production-3a52.up.railway.app/chat-fast';

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  bool get hasChatHistory => _messages.length > 1;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingData = true;
  bool get isLoadingData => _isLoadingData;

  bool _showBookingButton = false;
  bool get showBookingButton => _showBookingButton;

  final CustomerPreferences preferences = CustomerPreferences();

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> hairColors = [];
  List<Map<String, dynamic>> availabilitySlots = [];
  List<Map<String, dynamic>> bookingSignals = [];

  final List<KnowledgeDocument> knowledgeDocuments = [];

  String? lastSuggestedServiceName;

  final List<String> _lastMentionedServiceNames = [];

  DateTime? _lastSendAt;

  // ==========================================
  // SALON DATA
  // ==========================================

  Future<void> loadSalonData() async {
    _isLoadingData = true;
    notifyListeners();

    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      final rows = await _supabase
          .from('services')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);

      services = List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Could not load services: $error');
      services = [];
    }

    try {
      final rows = await _supabase
          .from('hair_colors')
          .select()
          .eq('is_active', true)
          .order('code', ascending: true);

      hairColors = List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Could not load hair colors: $error');
      hairColors = [];
    }

    try {
      final rows = await _supabase
          .from('availability_slots')
          .select(
            'id,slot_date,start_time,end_time,is_available',
          )
          .eq('is_available', true)
          .gte('slot_date', today)
          .order('slot_date', ascending: true)
          .limit(120);

      availabilitySlots = List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Could not load availability: $error');
      availabilitySlots = [];
    }

    try {
      final rows = await _supabase
          .from('bookings')
          .select(
            'service_id,booking_date,start_time,end_time,status,hair_color_code',
          )
          .gte('booking_date', today)
          .inFilter(
            'status',
            [
              'pending',
              'confirmed',
            ],
          )
          .order('booking_date', ascending: true)
          .limit(120);

      bookingSignals = List<Map<String, dynamic>>.from(rows);
    } catch (error) {
      debugPrint('Could not load booking occupancy: $error');
      bookingSignals = [];
    }

    _rebuildKnowledgeIndex();

    _isLoadingData = false;
    notifyListeners();
  }

  // ==========================================
  // KNOWLEDGE INDEX
  // ==========================================

  void _rebuildKnowledgeIndex() {
    knowledgeDocuments
      ..clear()
      ..addAll(_buildPageKnowledge());

    for (final service in services) {
      final id = (service['id'] ?? '').toString();

      final name = (service['name'] ?? 'Hairstyle').toString().trim();

      final category = (service['category'] ?? 'Style').toString().trim();

      final description = (service['description'] ?? '').toString().trim();

      final price = AIContextBuilder.money(service['price']);

      final duration = AIContextBuilder.duration(
        service['duration_minutes'],
      );

      final imageUrl = (service['image_url'] ?? '').toString().trim();

      knowledgeDocuments.add(
        KnowledgeDocument(
          id: 'service:$id:$name',
          source: KnowledgeSource.service,
          text: 'SERVICE: $name. Category: $category. '
              'Starting price: $price. '
              'Duration: $duration. '
              'Description: $description. '
              'Real salon image available: '
              '${imageUrl.isNotEmpty ? 'yes' : 'no'}.',
          serviceId: id,
          serviceName: name,
          imageUrl: imageUrl,
        ),
      );
    }

    for (final color in hairColors) {
      final code = (color['code'] ?? '').toString().trim();
      final name = (color['name'] ?? '').toString().trim();

      if (code.isEmpty && name.isEmpty) continue;

      knowledgeDocuments.add(
        KnowledgeDocument(
          id: 'hair-color:$code:$name',
          source: KnowledgeSource.hairColor,
          text: 'HAIR COLOR: code $code means $name.',
        ),
      );
    }

    for (final slot in availabilitySlots) {
      knowledgeDocuments.add(
        KnowledgeDocument(
          id:
              'availability:${slot['id'] ?? ''}:${slot['slot_date']}:${slot['start_time']}',
          source: KnowledgeSource.availability,
          text: 'OPEN APPOINTMENT SLOT: '
              'date ${slot['slot_date']}, '
              'from ${slot['start_time']} '
              'to ${slot['end_time']}.',
        ),
      );
    }

    for (final booking in bookingSignals) {
      final serviceId = (booking['service_id'] ?? '').toString();

      String serviceName = '';

      for (final service in services) {
        if ((service['id'] ?? '').toString() == serviceId) {
          serviceName = (service['name'] ?? '').toString().trim();
          break;
        }
      }

      knowledgeDocuments.add(
        KnowledgeDocument(
          id:
              'occupied:$serviceId:${booking['booking_date']}:${booking['start_time']}',
          source: KnowledgeSource.bookingOccupancy,
          text: 'BOOKED/OCCUPIED SLOT: '
              '${serviceName.isEmpty ? 'service id $serviceId' : serviceName}, '
              'date ${booking['booking_date']}, '
              '${booking['start_time']} to ${booking['end_time']}, '
              'status ${booking['status']}.',
        ),
      );
    }
  }

  List<KnowledgeDocument> _buildPageKnowledge() {
    return const [
      KnowledgeDocument(
        id: 'page:home',
        source: KnowledgeSource.page,
        text:
            'PAGE HOME: shows active salon services, style descriptions, starting prices, durations, and service cards.',
      ),
      KnowledgeDocument(
        id: 'page:gallery',
        source: KnowledgeSource.page,
        text:
            'PAGE GALLERY: shows real hairstyle photos from services.image_url in Supabase. Never invent a hairstyle photo.',
      ),
      KnowledgeDocument(
        id: 'page:ai',
        source: KnowledgeSource.page,
        text:
            'PAGE AI HELP: Faith AI helps customers compare listed styles, prices, duration, hair colors, and appointment availability.',
      ),
      KnowledgeDocument(
        id: 'page:book',
        source: KnowledgeSource.page,
        text:
            'PAGE BOOK: customers choose a service, date, time, and hair color and submit a booking.',
      ),
      KnowledgeDocument(
        id: 'page:live-chat',
        source: KnowledgeSource.page,
        text:
            'PAGE LIVE CHAT: lets a customer contact the salon owner for questions that need a human response.',
      ),
      KnowledgeDocument(
        id: 'page:social',
        source: KnowledgeSource.page,
        text:
            'PAGE SOCIAL: contains Faith Hair Style social/contact options including Instagram, TikTok, and WhatsApp.',
      ),
    ];
  }

  List<KnowledgeDocument> retrieveKnowledge(
    String query, {
    int limit = 10,
  }) {
    final enrichedQuery =
        '$query\n${preferences.toContextString()}';

    return LocalEmbeddingIndex.rank(
      knowledgeDocuments,
      enrichedQuery,
      limit: limit,
    );
  }

  // ==========================================
  // TYPO CORRECTION
  // ==========================================

  String _normalizeCustomerMessage(String text) {
    var value = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    final corrections = <RegExp, String>{
      RegExp(r'\bbriad\b', caseSensitive: false): 'braid',
      RegExp(r'\bbrad\b', caseSensitive: false): 'braid',
      RegExp(r'\bbrads\b', caseSensitive: false): 'braids',
      RegExp(r'\bbraide\b', caseSensitive: false): 'braid',
      RegExp(r'\bbraids\b', caseSensitive: false): 'braids',
      RegExp(r'\bknotles\b', caseSensitive: false): 'knotless',
      RegExp(r'\bknotlesss\b', caseSensitive: false): 'knotless',
      RegExp(r'\bsenegalise\b', caseSensitive: false): 'senegalese',
      RegExp(r'\bsenegales\b', caseSensitive: false): 'senegalese',
      RegExp(r'\bcornrowes\b', caseSensitive: false): 'cornrows',
      RegExp(r'\bcornrow\b', caseSensitive: false): 'cornrows',
      RegExp(r'\bponytail\b', caseSensitive: false): 'pony tail',
    };

    corrections.forEach(
      (pattern, replacement) {
        value = value.replaceAll(pattern, replacement);
      },
    );

    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ==========================================
  // SALON INTENT
  // ==========================================

  bool _isSalonIntent(String text) {
    final lower = _normalizeCustomerMessage(text).toLowerCase();

    const terms = [
      'braid',
      'braids',
      'hair',
      'hairstyle',
      'hairstyles',
      'style',
      'styles',
      'knotless',
      'cornrow',
      'cornrows',
      'twist',
      'twists',
      'senegalese',
      'boho',
      'fulani',
      'goddess',
      'lemonade',
      'pony tail',
      'ponytail',
      'loc',
      'locs',
      'box braid',
      'feed in',
      'feed-in',
      'color',
      'colour',
      'length',
      'medium',
      'small',
      'large',
      'jumbo',
      'price',
      'prices',
      'cost',
      'budget',
      'photo',
      'photos',
      'picture',
      'pictures',
      'image',
      'images',
      'gallery',
      'book',
      'booking',
      'appointment',
      'available',
      'availability',
      'salon',
    ];

    return terms.any(lower.contains);
  }

  // ==========================================
  // WRONG STATISTICS DETECTOR
  // ==========================================

  bool _looksLikeWrongStatisticsResponse(String text) {
    final lower = text.toLowerCase();

    var matches = 0;

    const strongSignals = [
      'statistics result',
      'sample variance',
      'population variance',
      'sample standard deviation',
      'population standard deviation',
    ];

    for (final signal in strongSignals) {
      if (lower.contains(signal)) {
        matches++;
      }
    }

    if (RegExp(r'\bcount\s*:').hasMatch(lower)) matches++;
    if (RegExp(r'\bmean\s*:').hasMatch(lower)) matches++;
    if (RegExp(r'\bmedian\s*:').hasMatch(lower)) matches++;
    if (RegExp(r'\bvariance\s*:').hasMatch(lower)) matches++;
    if (RegExp(r'\bstandard deviation\s*:').hasMatch(lower)) {
      matches++;
    }

    return matches >= 2;
  }

  // ==========================================
  // LOCAL SALON FALLBACK
  // ==========================================

  String _salonFallback(String customerMessage) {
    final lower =
        _normalizeCustomerMessage(customerMessage).toLowerCase();

    if (lower.contains('braid') ||
        lower.contains('cornrow') ||
        lower.contains('knotless') ||
        lower.contains('fulani')) {
      final braidServices = services.where(
        (service) {
          final searchable =
              '${service['name'] ?? ''} '
                      '${service['category'] ?? ''} '
                      '${service['description'] ?? ''}'
                  .toLowerCase();

          return searchable.contains('braid') ||
              searchable.contains('cornrow') ||
              searchable.contains('knotless') ||
              searchable.contains('fulani');
        },
      ).take(3).toList();

      if (braidServices.isNotEmpty) {
        final names = braidServices.map(
          (service) {
            final name = _serviceName(service);
            final price = AIContextBuilder.money(service['price']);

            return '• $name — starting at $price';
          },
        ).join('\n');

        return '''
Absolutely! Here are some braid styles from our live salon catalog:

$names

Which one would you like to see?
'''
            .trim();
      }

      return 'Absolutely! I can help you choose a braid style. Tell me the style, size, length, or budget you prefer.';
    }

    if (lower.contains('twist')) {
      final twists = services.where(
        (service) {
          final searchable =
              '${service['name'] ?? ''} ${service['description'] ?? ''}'
                  .toLowerCase();

          return searchable.contains('twist');
        },
      ).take(3).toList();

      if (twists.isNotEmpty) {
        return twists
            .map(
              (service) =>
                  '• ${_serviceName(service)} — starting at ${AIContextBuilder.money(service['price'])}',
            )
            .join('\n');
      }
    }

    if (lower.contains('budget')) {
      if (preferences.budget == null) {
        return 'Absolutely. What is your hairstyle budget?';
      }

      return 'I can help you find styles within your ${preferences.budget} budget. Tell me whether you prefer braids, twists, cornrows, or another style.';
    }

    if (lower.contains('available') ||
        lower.contains('availability') ||
        lower.contains('appointment') ||
        lower.contains('open time')) {
      if (availabilitySlots.isEmpty) {
        return 'I do not see an open appointment slot in the live availability data right now. You can check Live Chat for help.';
      }

      final slots = availabilitySlots.take(3).map(
        (slot) =>
            '• ${slot['slot_date']} — ${slot['start_time']} to ${slot['end_time']}',
      );

      return 'Here are the next open appointment times:\n\n${slots.join('\n')}';
    }

    return 'I can help with Faith Hair Style services, hairstyles, prices, colors, real salon photos, availability, and booking. What hairstyle are you interested in?';
  }

  // ==========================================
  // SEND MESSAGE
  // ==========================================

  Future<void> sendMessage(String text) async {
    final originalText = text.trim();

    if (originalText.isEmpty || _isLoading) return;

    final cleanText = _normalizeCustomerMessage(originalText);

    final now = DateTime.now();

    if (_lastSendAt != null &&
        now.difference(_lastSendAt!).inMilliseconds < 450) {
      return;
    }

    _lastSendAt = now;

    preferences.extractAndRemember(cleanText);

    _messages.add(
      ChatMessage(
        text: originalText,
        isUser: true,
      ),
    );

    _isLoading = true;

    // Prevent an old service's booking button from leaking into
    // an unrelated new conversation turn.
    if (_isBookingIntent(cleanText)) {
      _showBookingButton = lastSuggestedServiceName != null;
    } else {
      _showBookingButton = false;
    }

    notifyListeners();

    try {
      if (_isGreeting(cleanText)) {
        _messages.add(
          const ChatMessage(
            text:
                'Hi! I’m Faith AI. I can help you choose a hairstyle, compare starting prices, show real salon photos, check colors, and get ready to book.',
            isUser: false,
          ),
        );

        return;
      }

      if (services.isEmpty) {
        await loadSalonData();
      }

      if (_isImageRequest(cleanText)) {
        final handled = _handleImageRequestLocally(cleanText);

        if (handled) return;
      }

      if (_isDirectServicePreviewRequest(cleanText)) {
        final matched = _findServicesFromText(cleanText);

        if (matched.isNotEmpty) {
          _addImageMessage(
            matched,
            intro: matched.length == 1
                ? 'Here is ${_serviceName(matched.first)} from our live salon catalog.'
                : 'Here are the matching styles from our live salon catalog.',
            includeMissingNote: true,
          );

          return;
        }
      }

      final reply = await _fetchAIResponse(cleanText);

      final cleanedReply = _removeRepeatedGreeting(reply);

      _processAIResponse(
        cleanText,
        cleanedReply,
      );
    } catch (error, stackTrace) {
      debugPrint('Faith AI request failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (_isSalonIntent(cleanText)) {
        _messages.add(
          ChatMessage(
            text: _salonFallback(cleanText),
            isUser: false,
          ),
        );
      } else {
        _messages.add(
          const ChatMessage(
            text:
                'Faith AI is taking longer than expected. You can still ask me about a hairstyle, price, salon photo, color, availability, or booking.',
            isUser: false,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isGreeting(String text) {
    final value = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    const greetings = {
      'h',
      'hi',
      'hello',
      'hey',
      'hey there',
      'good morning',
      'good afternoon',
      'good evening',
    };

    return greetings.contains(value);
  }

  // ==========================================
  // IMAGE REQUESTS
  // ==========================================

  bool _isDirectServicePreviewRequest(String text) {
    final lower = text.toLowerCase();

    final wantsPreview = lower.contains('show me') ||
        lower.contains('let me see') ||
        lower.contains('see the') ||
        lower.contains('view ') ||
        lower.startsWith('show ');

    if (!wantsPreview) return false;

    return _findServicesFromText(text).isNotEmpty;
  }

  bool _isImageRequest(String text) {
    final lower = text.toLowerCase();

    return lower.contains('image') ||
        lower.contains('images') ||
        lower.contains('photo') ||
        lower.contains('photos') ||
        lower.contains('picture') ||
        lower.contains('pictures') ||
        lower.contains('pic ') ||
        lower.endsWith(' pic') ||
        lower.contains('gallery');
  }

  bool _asksForAllImages(String text) {
    final lower = text.toLowerCase();

    return _isImageRequest(text) &&
        (lower.contains('all ') ||
            lower.contains('all the') ||
            lower.contains('every ') ||
            lower.contains('available images') ||
            lower.contains('available photos'));
  }

  bool _handleImageRequestLocally(String userText) {
    if (!_isImageRequest(userText)) return false;

    final candidates = _resolveServicesForImageRequest(userText);

    if (candidates.isEmpty) {
      final available = services
          .where(
            (service) =>
                (service['image_url'] ?? '').toString().trim().isNotEmpty,
          )
          .toList();

      if (available.isEmpty) {
        _messages.add(
          const ChatMessage(
            text:
                'There are no salon service photos available in the catalog right now.',
            isUser: false,
          ),
        );

        return true;
      }

      if (_asksForAllImages(userText)) {
        _addImageMessage(
          available,
          intro:
              'Here are the real salon photos currently available in our service catalog.',
          includeMissingNote: true,
        );

        return true;
      }

      _messages.add(
        const ChatMessage(
          text:
              'Tell me which hairstyle you want to see, or say “show me all the images.”',
          isUser: false,
        ),
      );

      return true;
    }

    _addImageMessage(
      candidates,
      intro: candidates.length == 1
          ? 'Here is the real salon photo for ${_serviceName(candidates.first)}.'
          : 'Here are the real salon photos for the styles we were discussing.',
      includeMissingNote: true,
    );

    return true;
  }

  void _addImageMessage(
    List<Map<String, dynamic>> candidateServices, {
    required String intro,
    bool includeMissingNote = false,
  }) {
    final attachments = <ServiceImageAttachment>[];
    final missing = <String>[];
    final seen = <String>{};

    for (final service in candidateServices) {
      final name = _serviceName(service);
      final id = (service['id'] ?? '').toString();
      final key = id.isNotEmpty ? id : name.toLowerCase();

      if (!seen.add(key)) continue;

      final imageUrl = (service['image_url'] ?? '').toString().trim();

      if (imageUrl.isEmpty) {
        missing.add(name);
        continue;
      }

      attachments.add(
        ServiceImageAttachment(
          serviceName: name,
          url: imageUrl,
        ),
      );
    }

    var messageText = intro;

    if (attachments.isEmpty) {
      messageText = missing.length == 1
          ? 'I do not have a real salon photo for ${missing.first} in the database yet.'
          : 'I do not have real salon photos for those styles in the database yet.';
    } else if (includeMissingNote && missing.isNotEmpty) {
      messageText +=
          '\n\nNo real catalog image is stored yet for: ${missing.join(', ')}.';
    }

    _messages.add(
      ChatMessage(
        text: messageText,
        isUser: false,
        serviceImages: attachments,
      ),
    );

    if (candidateServices.isNotEmpty) {
      lastSuggestedServiceName =
          _serviceName(candidateServices.first);

      _lastMentionedServiceNames
        ..clear()
        ..addAll(
          candidateServices
              .map(_serviceName)
              .where((name) => name.isNotEmpty),
        );

      _showBookingButton = true;
    }
  }

  List<Map<String, dynamic>> _resolveServicesForImageRequest(
    String userText,
  ) {
    final output = <Map<String, dynamic>>[];
    final seen = <String>{};

    void add(Map<String, dynamic> service) {
      final id = (service['id'] ?? '').toString();
      final name = _serviceName(service);
      final key = id.isNotEmpty ? id : name.toLowerCase();

      if (key.isEmpty || !seen.add(key)) return;

      output.add(service);
    }

    for (final service in _findServicesFromText(userText)) {
      add(service);
    }

    if (_asksForAllImages(userText)) {
      for (final service in services) {
        add(service);
      }

      return output;
    }

    if (output.isEmpty) {
      for (final rememberedName in _lastMentionedServiceNames) {
        final service = _findServiceByExactName(rememberedName);

        if (service != null) add(service);
      }
    }

    if (output.isEmpty && lastSuggestedServiceName != null) {
      final service =
          _findServiceByExactName(lastSuggestedServiceName!);

      if (service != null) add(service);
    }

    if (output.isEmpty) {
      for (var i = _messages.length - 2; i >= 0; i--) {
        for (final service in _findServicesFromText(_messages[i].text)) {
          add(service);
        }

        if (output.isNotEmpty) break;
      }
    }

    return output.take(8).toList(growable: false);
  }

  Map<String, dynamic>? _findServiceByExactName(String name) {
    final wanted = name.trim().toLowerCase();

    if (wanted.isEmpty) return null;

    for (final service in services) {
      final serviceName = _serviceName(service).toLowerCase();

      if (serviceName == wanted) return service;
    }

    return null;
  }

  String _serviceName(Map<String, dynamic> service) {
    return (service['name'] ?? 'Hairstyle').toString().trim();
  }

  void addSystemMessage(String text) {
    _messages.add(
      ChatMessage(
        text: text,
        isUser: false,
      ),
    );

    notifyListeners();
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
        r"^(?:i['’]?m|i am)\s+faith\s+ai(?:,\s*your\s+salon\s+copilot)?[!,.:\-\s]*",
        caseSensitive: false,
      ),
      '',
    );

    if (cleaned.isEmpty) return text.trim();

    return cleaned.trimLeft();
  }

  // ==========================================
  // PROCESS AI RESPONSE
  // ==========================================

  void _processAIResponse(
    String userText,
    String aiText,
  ) {
    if (_isSalonIntent(userText) &&
        _looksLikeWrongStatisticsResponse(aiText)) {
      // Clear stale recommendation state.
      _showBookingButton = false;
      lastSuggestedServiceName = null;
      _lastMentionedServiceNames.clear();

      _messages.add(
        ChatMessage(
          text: _salonFallback(userText),
          isUser: false,
        ),
      );

      return;
    }

    final detectedServices = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addService(Map<String, dynamic> service) {
      final id = (service['id'] ?? '').toString();
      final name = _serviceName(service);
      final key = id.isNotEmpty ? id : name.toLowerCase();

      if (key.isEmpty || !seen.add(key)) return;

      detectedServices.add(service);
    }

    for (final service in _servicesFromMarkers(aiText)) {
      addService(service);
    }

    for (final service in _findServicesFromText(aiText)) {
      addService(service);
    }

    if (detectedServices.isEmpty) {
      for (final service in _findServicesFromText(userText)) {
        addService(service);
      }
    }

    if (detectedServices.isEmpty &&
        _looksLikeStyleRequest(userText)) {
      for (final doc in retrieveKnowledge(
        userText,
        limit: 12,
      )) {
        if (doc.source != KnowledgeSource.service) continue;

        final service = _serviceFromKnowledgeDocument(doc);

        if (service != null) {
          addService(service);
        }

        if (detectedServices.length >= 3) break;
      }
    }

    final imageAttachments = detectedServices
        .map(
          (service) {
            final name = _serviceName(service);

            final imageUrl =
                (service['image_url'] ?? '').toString().trim();

            if (imageUrl.isEmpty) return null;

            return ServiceImageAttachment(
              serviceName: name,
              url: imageUrl,
            );
          },
        )
        .whereType<ServiceImageAttachment>()
        .take(3)
        .toList(growable: false);

    final visibleText = _sanitizeAIReply(aiText);

    _messages.add(
      ChatMessage(
        text: visibleText,
        isUser: false,
        serviceImages: imageAttachments,
      ),
    );

    if (detectedServices.isNotEmpty) {
      lastSuggestedServiceName =
          _serviceName(detectedServices.first);

      _lastMentionedServiceNames
        ..clear()
        ..addAll(
          detectedServices
              .map(_serviceName)
              .where((name) => name.isNotEmpty),
        );

      // Current response actually contains a real service.
      _showBookingButton = true;
    }

    final lowerReply = visibleText.toLowerCase();

    if ((_isBookingIntent(visibleText) ||
            lowerReply.contains('open booking')) &&
        lastSuggestedServiceName != null) {
      _showBookingButton = true;
    }
  }

  Map<String, dynamic>? _serviceFromKnowledgeDocument(
    KnowledgeDocument doc,
  ) {
    for (final service in services) {
      final id = (service['id'] ?? '').toString();
      final name = _serviceName(service);

      if ((doc.serviceId != null &&
              doc.serviceId!.isNotEmpty &&
              id == doc.serviceId) ||
          (doc.serviceName != null &&
              name.toLowerCase() == doc.serviceName!.toLowerCase())) {
        return service;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _servicesFromMarkers(String text) {
    final output = <Map<String, dynamic>>[];
    final seen = <String>{};

    final marker = RegExp(
      r'\[\[service\s*:\s*([^\]]+)\]\]',
      caseSensitive: false,
    );

    for (final match in marker.allMatches(text)) {
      final requestedName = (match.group(1) ?? '').trim();

      if (requestedName.isEmpty) continue;

      Map<String, dynamic>? service =
          _findServiceByExactName(requestedName);

      service ??= _findServiceFromText(requestedName);

      if (service == null) continue;

      final id = (service['id'] ?? '').toString();
      final name = _serviceName(service);
      final key = id.isNotEmpty ? id : name.toLowerCase();

      if (key.isNotEmpty && seen.add(key)) {
        output.add(service);
      }
    }

    return output;
  }

  String _sanitizeAIReply(String text) {
    var cleaned = text;

    cleaned = cleaned.replaceAll(
      RegExp(
        r'\[\[service\s*:\s*[^\]]+\]\]',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.replaceAll(
      RegExp(
        r'^\s*(?:[-*]\s*)?image\s*\d+\s*[:.\-]\s*.*$',
        caseSensitive: false,
        multiLine: true,
      ),
      '',
    );

    cleaned = cleaned.replaceAll(
      RegExp(
        r'^\s*(?:[-*]\s*)?(?:photo|picture)\s*\d+\s*[:.\-]\s*.*$',
        caseSensitive: false,
        multiLine: true,
      ),
      '',
    );

    cleaned = cleaned
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (cleaned.isEmpty) {
      return 'I found the matching salon style. The app will show the real catalog photo when one is available.';
    }

    return cleaned;
  }

  // ============================================================
  // BACKEND REQUEST
  // ============================================================

  Future<String> _fetchAIResponse(String customerMessage) async {
    final normalizedMessage =
        _normalizeCustomerMessage(customerMessage);

    final systemPrompt = AIContextBuilder.buildPrompt(
      this,
      normalizedMessage,
    );

    final response = await http
        .post(
          Uri.parse(_aiEndpoint),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(
            {
              'message': systemPrompt,
              'user_message': normalizedMessage,

              // Faith-specific routing information.
              'app': 'faith_hairstyle',
              'assistant': 'faith_ai',
              'domain': 'hair_salon',
              'mode': 'salon_copilot',
            },
          ),
        )
        .timeout(
          const Duration(seconds: 80),
        );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Faith AI server returned ${response.statusCode}: ${response.body}',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      final plain = response.body.trim();

      if (plain.isEmpty) {
        throw Exception('Faith AI returned an empty response.');
      }

      if (_isSalonIntent(normalizedMessage) &&
          _looksLikeWrongStatisticsResponse(plain)) {
        debugPrint(
          'Blocked incorrect statistics response.',
        );

        return _salonFallback(normalizedMessage);
      }

      return plain;
    }

    var answer = _extractAIText(decoded);

    if (answer.isEmpty) {
      throw Exception(
        'Faith AI returned an unreadable response.',
      );
    }

    if (_isSalonIntent(normalizedMessage) &&
        _looksLikeWrongStatisticsResponse(answer)) {
      debugPrint(
        'Faith AI blocked statistics response for salon request.',
      );

      answer = _salonFallback(normalizedMessage);
    }

    return answer;
  }

  String _extractAIText(dynamic data) {
    if (data is String) {
      return data.trim();
    }

    if (data is Map) {
      const directKeys = [
        'reply',
        'response',
        'message',
        'answer',
        'content',
        'text',
        'output',
      ];

      for (final key in directKeys) {
        final value = data[key];

        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final choices = data['choices'];

      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;

        if (first is Map) {
          final message = first['message'];

          if (message is Map && message['content'] is String) {
            return (message['content'] as String).trim();
          }

          if (first['text'] is String) {
            return (first['text'] as String).trim();
          }
        }
      }
    }

    return '';
  }

  // ==========================================
  // BOOKING
  // ==========================================

  Map<String, dynamic>? getSuggestedService() {
    if (lastSuggestedServiceName == null) return null;

    try {
      return services.firstWhere(
        (service) =>
            (service['name'] ?? '').toString() ==
            lastSuggestedServiceName,
      );
    } catch (_) {
      return null;
    }
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

  bool _looksLikeStyleRequest(String text) {
    final lower =
        _normalizeCustomerMessage(text).toLowerCase();

    const terms = [
      'recommend',
      'suggest',
      'style',
      'hairstyle',
      'braid',
      'braids',
      'twist',
      'twists',
      'cornrow',
      'cornrows',
      'knotless',
      'fulani',
      'boho',
      'loc',
      'protective',
      'look',
      'hair',
      'budget',
      'price',
      'picture',
      'photo',
      'image',
    ];

    return terms.any(lower.contains);
  }

  // ==========================================
  // SERVICE MATCHING
  // ==========================================

  List<Map<String, dynamic>> _findServicesFromText(String text) {
    final lower = _normalizeServiceLookup(
      _normalizeCustomerMessage(text),
    );

    final matches = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addService(Map<String, dynamic> service) {
      final id = (service['id'] ?? '').toString();
      final name = _serviceName(service);
      final key = id.isNotEmpty ? id : name.toLowerCase();

      if (key.isEmpty || !seen.add(key)) return;

      matches.add(service);
    }

    final orderedServices = [...services]
      ..sort(
        (a, b) => _serviceName(b)
            .length
            .compareTo(_serviceName(a).length),
      );

    for (final service in orderedServices) {
      final name = _normalizeServiceLookup(
        _serviceName(service),
      );

      if (name.isNotEmpty && lower.contains(name)) {
        addService(service);
      }
    }

    final aliases = <String, List<String>>{
      'Cornrows': [
        'cornrow',
        'cornrows',
        'natural cornrow',
        'natural cornrows',
      ],
      'Extra small knotless with coil': [
        'extra small knotless with coil',
        'extra small knotless coil',
        'small knotless with coil',
      ],
      'Fulani Braids': [
        'fulani',
        'fulani braid',
        'fulani braids',
      ],
      'Kids Styling': [
        'kids styling',
        'kid styling',
        'children styling',
        'child styling',
        'kids hair',
      ],
      'Pony tail': [
        'pony tail',
        'ponytail',
      ],
      'Box Braids': [
        'box braid',
        'box braids',
      ],
      'Feed-In Braids': [
        'feed in braid',
        'feed in braids',
        'feed-in braid',
        'feed-in braids',
      ],
      'Goddess Braids': [
        'goddess braid',
        'goddess braids',
      ],
      'Knotless Braids': [
        'knotless braid',
        'knotless braids',
        'knotless',
      ],
      'Lemonade Braids': [
        'lemonade braid',
        'lemonade braids',
        'lemonade',
      ],
      'Passion Twists': [
        'passion twist',
        'passion twists',
      ],
      'Twists': [
        'natural twist',
        'natural twists',
        'twist',
        'twists',
      ],
    };

    for (final entry in aliases.entries) {
      final aliasMatched = entry.value
          .map(_normalizeServiceLookup)
          .any(
            (alias) => alias.isNotEmpty && lower.contains(alias),
          );

      if (!aliasMatched) continue;

      final exactService = _findServiceByExactName(entry.key);

      if (exactService != null) {
        addService(exactService);
      }
    }

    return matches.take(8).toList(growable: false);
  }

  String _normalizeServiceLookup(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Map<String, dynamic>? _findServiceFromText(String text) {
    final matches = _findServicesFromText(text);

    return matches.isEmpty ? null : matches.first;
  }
}

// ============================================================
// 5. DATA CLASSES
// ============================================================

class ServiceImageAttachment {
  final String serviceName;
  final String url;

  const ServiceImageAttachment({
    required this.serviceName,
    required this.url,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<ServiceImageAttachment> serviceImages;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.serviceImages = const [],
  });
}

enum KnowledgeSource {
  page,
  service,
  hairColor,
  availability,
  bookingOccupancy,
}

class KnowledgeDocument {
  final String id;
  final KnowledgeSource source;
  final String text;

  final String? serviceId;
  final String? serviceName;
  final String? imageUrl;

  const KnowledgeDocument({
    required this.id,
    required this.source,
    required this.text,
    this.serviceId,
    this.serviceName,
    this.imageUrl,
  });
}

class _KnowledgeScore {
  final KnowledgeDocument document;
  final double score;

  const _KnowledgeScore(
    this.document,
    this.score,
  );
}

// ============================================================
// 6. LOCAL EMBEDDING / KNOWLEDGE RANKING
// ============================================================

class LocalEmbeddingIndex {
  static const int _dimensions = 256;

  static List<KnowledgeDocument> rank(
    List<KnowledgeDocument> documents,
    String query, {
    int limit = 10,
  }) {
    if (documents.isEmpty) {
      return const [];
    }

    final q = query.trim();

    if (q.isEmpty) {
      return documents.take(limit).toList(growable: false);
    }

    final queryVector = _embed(q);
    final lower = q.toLowerCase();

    final scored = documents.map(
      (document) {
        final docVector = _embed(document.text);

        var score = _dot(
          queryVector,
          docVector,
        );

        score += _intentBoost(
          lower,
          document.source,
        );

        final serviceName =
            document.serviceName?.toLowerCase().trim() ?? '';

        if (serviceName.isNotEmpty &&
            lower.contains(serviceName)) {
          score += .55;
        }

        return _KnowledgeScore(
          document,
          score,
        );
      },
    ).toList()
      ..sort(
        (a, b) => b.score.compareTo(a.score),
      );

    final output = <KnowledgeDocument>[];
    final seen = <String>{};

    for (final item in scored) {
      if (!seen.add(item.document.id)) continue;

      if (item.score < .01 && output.length >= 4) {
        continue;
      }

      output.add(item.document);

      if (output.length >= limit) break;
    }

    return output;
  }

  static double _intentBoost(
    String query,
    KnowledgeSource source,
  ) {
    bool hasAny(List<String> values) =>
        values.any(query.contains);

    if (hasAny([
      'recommend',
      'suggest',
      'style',
      'hairstyle',
      'braid',
      'twist',
      'loc',
      'cornrow',
      'hair',
      'budget',
      'price',
      'cost',
    ])) {
      if (source == KnowledgeSource.service) {
        return .24;
      }
    }

    if (hasAny([
      'color',
      'colour',
      '1b',
      '27',
      '30',
      '613',
    ])) {
      if (source == KnowledgeSource.hairColor) {
        return .32;
      }
    }

    if (hasAny([
      'available',
      'availability',
      'appointment',
      'book',
      'booking',
      'schedule',
      'time',
      'today',
      'tomorrow',
    ])) {
      if (source == KnowledgeSource.availability) {
        return .34;
      }

      if (source == KnowledgeSource.bookingOccupancy) {
        return .20;
      }

      if (source == KnowledgeSource.page) {
        return .08;
      }
    }

    if (hasAny([
      'gallery',
      'photo',
      'picture',
      'image',
      'instagram',
      'tiktok',
      'whatsapp',
      'social',
      'live chat',
      'page',
    ])) {
      if (source == KnowledgeSource.page) {
        return .28;
      }

      if (source == KnowledgeSource.service) {
        return .10;
      }
    }

    return 0;
  }

  static List<double> _embed(String text) {
    final vector = List<double>.filled(
      _dimensions,
      0.0,
    );

    final tokens = _tokens(text);

    if (tokens.isEmpty) return vector;

    final features = <String>[
      ...tokens,
    ];

    for (var i = 0; i + 1 < tokens.length; i++) {
      features.add(
        '${tokens[i]}_${tokens[i + 1]}',
      );
    }

    for (final feature in features) {
      final hash = _fnv1a(feature);
      final index = hash % _dimensions;

      final sign =
          ((hash >> 8) & 1) == 0 ? 1.0 : -1.0;

      vector[index] += sign;
    }

    var sumSquares = 0.0;

    for (final value in vector) {
      sumSquares += value * value;
    }

    final norm = math.sqrt(sumSquares);

    if (norm == 0) return vector;

    for (var i = 0; i < vector.length; i++) {
      vector[i] /= norm;
    }

    return vector;
  }

  static List<String> _tokens(String text) {
    final raw = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1)
        .toList();

    final expanded = <String>[];

    for (final token in raw) {
      expanded.add(token);

      switch (token) {
        case 'briad':
          expanded.add('braid');
          break;

        case 'braids':
          expanded.add('braid');
          break;

        case 'twists':
          expanded.add('twist');
          break;

        case 'kids':
        case 'child':
        case 'children':
          expanded.add('kid');
          break;

        case 'pictures':
        case 'photos':
          expanded.add('image');
          break;

        case 'booking':
        case 'appointment':
          expanded.add('book');
          break;
      }
    }

    return expanded;
  }

  static int _fnv1a(String value) {
    var hash = 0x811C9DC5;

    for (final unit in value.codeUnits) {
      hash ^= unit;

      hash =
          (hash * 0x01000193) &
              0x7FFFFFFF;
    }

    return hash;
  }

  static double _dot(
    List<double> a,
    List<double> b,
  ) {
    final length = math.min(
      a.length,
      b.length,
    );

    var sum = 0.0;

    for (var i = 0; i < length; i++) {
      sum += a[i] * b[i];
    }

    return sum;
  }
}

// ============================================================
// 7. CUSTOMER PREFERENCES
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
      if (lower.contains(value)) {
        length = value;
      }
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
      if (lower.contains(value)) {
        size = value;
      }
    }

    final colorMatch = RegExp(
      r'(?:color|colour)\s*(?:#|number|no\.?|code)?\s*([0-9]{1,3}[a-z]?)',
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
      if (lower.contains(value)) {
        occasion = value;
      }
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

    final mentioned =
        dateWords.where(lower.contains).toList();

    if (mentioned.isNotEmpty) {
      datePreference = mentioned.join(', ');
    }
  }

  String toContextString() {
    final list = [
      if (budget != null) 'Budget: $budget',
      if (length != null) 'Length: $length',
      if (size != null) 'Size: $size',
      if (color != null) 'Color: $color',
      if (occasion != null) 'Occasion: $occasion',
      if (datePreference != null)
        'Date/time preference: $datePreference',
    ];

    return list.isEmpty
        ? 'No preferences set.'
        : list.join('\n');
  }
}

// ============================================================
// 8. AI CONTEXT BUILDER
// ============================================================

class AIContextBuilder {
  static String buildPrompt(
    FaithCopilotController controller,
    String latestMessage,
  ) {
    final retrieved = controller.retrieveKnowledge(
      latestMessage,
      limit: 6,
    );

    final knowledgeContext = retrieved.isEmpty
        ? 'No matching live salon records were found.'
        : retrieved
            .map(
              (doc) => '- ${_clip(doc.text, 260)}',
            )
            .join('\n');

    final recentMessages = controller.messages.length > 4
        ? controller.messages.sublist(
            controller.messages.length - 4,
          )
        : controller.messages;

    final chatContext = recentMessages.map(
      (message) {
        final role =
            message.isUser ? 'Customer' : 'Faith AI';

        return '$role: ${_clip(message.text, 180)}';
      },
    ).join('\n');

    final prompt = '''
You are Faith AI Copilot, the customer-facing salon assistant for Faith Hair Style.

IDENTITY AND DOMAIN
You are operating inside the Faith Hair Style website.
This conversation is primarily about hair, hairstyles, salon services, prices, colors, photos, availability, and booking.

GOAL
Answer the customer's question using the retrieved LIVE salon knowledge below.
Help the customer choose a listed hairstyle, compare starting prices and durations, view real salon images, understand hair colors, and move toward booking when ready.

SALON-FIRST ROUTING
- Interpret short messages such as "braid", "braids", "briad", "hair", "knotless", "twist", "cornrows", "boho", "fulani", "locs", and similar wording as salon hairstyle requests.
- Correct obvious hairstyle spelling mistakes using the salon context.
- A short or misspelled hairstyle word is NOT a request for mathematical analysis.
- A number in a salon conversation normally represents a price, budget, hair-color code, braid size, length, date, duration, or appointment time.

NO ACCIDENTAL STATISTICS
- NEVER return a statistics analysis for a hairstyle or salon request.
- NEVER return "Statistics result" for a salon request.
- NEVER calculate count, mean, median, variance, standard deviation, regression, probability, or other statistical measures unless the customer explicitly asks a mathematical/statistical question.
- Do not interpret service prices, durations, database values, IDs, image metadata, or appointment data as a dataset to analyze.
- If the customer's wording is ambiguous but contains a hair or salon term, interpret it as a Faith Hair Style request.

STRICT LIVE-DATA RULES
- RETRIEVED LIVE KNOWLEDGE comes from Faith Hair Style's customer-facing pages and live Supabase records.
- Treat the retrieved live salon knowledge as the source of truth.
- Recommend ONLY service names that appear in the retrieved/live catalog data.
- NEVER invent a salon service.
- NEVER combine a category with a service name to create a new service name.
- If the live record is "Cornrows", say "Cornrows", not "Natural Cornrows".

SERVICE MARKERS
Whenever you recommend or discuss a specific service, write its EXACT live service name and append:
[[service:EXACT SERVICE NAME]]

For recommendations, prefer 1 to 3 exact services.

IMAGES
- Never invent a style image.
- Never invent an image URL.
- Never output fake Markdown images.
- Never say "Image 1", "Image 2", "Photo 1", or similar placeholders.
- The Flutter app renders real services.image_url values.
- If the customer requests an image, identify the exact live service and let the app display the image.

PRICES
- Always say "starting at" when quoting service prices.
- Never invent a price.
- Never invent a discount.
- Never invent a deposit.
- Never invent a payment method or salon policy.

AVAILABILITY
- An OPEN APPOINTMENT SLOT represents availability.
- A BOOKED/OCCUPIED SLOT is not available.
- Never invent appointment availability.

PRIVACY
- Never reveal another customer's name.
- Never reveal another customer's phone number.
- Never reveal another customer's email.
- Never reveal another customer's notes or messages.
- Never reveal owner-only/private information.

MISSING INFORMATION
If the requested fact is not present in the retrieved live salon knowledge, say that you do not have that information.
Guide the customer to Live Chat when a human response is appropriate.

BOOKING
When the customer is ready to book a known service, tell them to tap the booking button.

CONVERSATION STYLE
- Be warm, concise, polished, and direct.
- Ask at most one important follow-up question at a time.
- Do not repeatedly greet the customer.
- Do not repeatedly introduce yourself.
- Focus on helping the customer choose and book a hairstyle.

CUSTOMER PREFERENCES
${controller.preferences.toContextString()}

RETRIEVED LIVE SALON KNOWLEDGE
$knowledgeContext

RECENT CONVERSATION
$chatContext

LATEST CUSTOMER MESSAGE
${_clip(latestMessage, 500)}
'''
        .trim();

    if (prompt.length <= 5200) {
      return prompt;
    }

    final latestBlock =
        '\n\nLATEST CUSTOMER MESSAGE\n${_clip(latestMessage, 500)}';

    final room = 5200 - latestBlock.length;

    if (room <= 0) {
      return latestBlock.substring(
        0,
        math.min(
          5200,
          latestBlock.length,
        ),
      );
    }

    return '${prompt.substring(0, room)}$latestBlock';
  }

  static String _clip(
    String value,
    int maxLength,
  ) {
    final clean = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.length <= maxLength) {
      return clean;
    }

    return '${clean.substring(0, maxLength - 1)}…';
  }

  static String money(dynamic value) {
    if (value == null) {
      return 'not listed';
    }

    final parsed =
        double.tryParse(value.toString());

    if (parsed == null) {
      return value.toString();
    }

    if (parsed == parsed.roundToDouble()) {
      return '\$${parsed.toStringAsFixed(0)}';
    }

    return '\$${parsed.toStringAsFixed(2)}';
  }

  static String duration(dynamic value) {
    final minutes =
        int.tryParse(value?.toString() ?? '');

    if (minutes == null || minutes <= 0) {
      return 'not listed';
    }

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (hours == 0) {
      return '$minutes minutes';
    }

    if (remainder == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    return '$hours hr $remainder min';
  }
}

// ============================================================
// 9. COLORS
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
