
importimport 'dart:convert';
import 'dart:math' as math;
 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'booking_page.dart';

// ==========================================
// 1. SHELL & LAUNCHER (UI)
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
    setState(() => _isOpen = !_isOpen);
  }

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
                        hasActiveChat: FaithCopilotController.instance.hasChatHistory,
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
                  'Faith AI',
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

// Backward-compatible full-page entry used by customer_home_page.dart.
class AIChatPage extends StatelessWidget {
  const AIChatPage({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Faith AI'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: FaithAICopilotPanel(
            navigatorKey: navigatorKey,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANEL (UI)
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
              _speechError ??
                  'Microphone access is unavailable. Check browser/device permissions.',
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
      partialResults: true,
      cancelOnError: true,
      onResult: (result) {
        if (!mounted) return;

        final rawWords = result.recognizedWords.trim();
        var words = rawWords;

        // Some mobile browsers can return the same recognition result twice
        // joined together, for example: "hellohello" or
        // "good morninggood morning". Collapse an exact repeated half.
        if (rawWords.length >= 2 && rawWords.length.isEven) {
          final half = rawWords.length ~/ 2;
          final firstHalf = rawWords.substring(0, half);
          final secondHalf = rawWords.substring(half);

          if (firstHalf.toLowerCase() == secondHalf.toLowerCase()) {
            words = firstHalf;
          }
        }

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
                  itemCount: _controller.messages.length + (_controller.isLoading ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (_controller.isLoading && index == _controller.messages.length) {
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
          colors: [AppColors.navy, AppColors.deepBlue, AppColors.royalBlue],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.navy, size: 21),
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
            onPressed: _controller.isLoadingData ? null : _controller.loadSalonData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
          ),
          if (widget.onMinimize != null)
            IconButton(
              tooltip: 'Minimize',
              onPressed: widget.onMinimize,
              icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 23),
            ),
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Close',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 21),
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
            onTap: () => _sendMessage('Help me choose the best hairstyle. Ask only one useful question if you still need information.'),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Under my budget',
            icon: Icons.savings_outlined,
            onTap: () => _sendMessage('Help me find hairstyles that fit my budget. Ask my budget if I have not told you yet.'),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Open times',
            icon: Icons.schedule_rounded,
            onTap: () => _sendMessage('Show me the next available appointment times.'),
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
            serviceName == null ? 'OPEN BOOKING' : 'BOOK ${serviceName.toUpperCase()}',
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
        border: Border(top: BorderSide(color: AppColors.borderLight)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
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
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. UI COMPONENTS (UPDATED WITH IMAGE SUPPORT)
// ==========================================

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
          gradient: isUser ? const LinearGradient(colors: [AppColors.gold, Color(0xFFF0BC27)]) : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.deepGold),
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
              _ServiceRecommendationImages(images: message.serviceImages),
            ],
          ],
        ),
      ),
    );
  }
}


class _ServiceRecommendationImages extends StatelessWidget {
  const _ServiceRecommendationImages({required this.images});

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

/// Parses the AI message for Markdown Images ![alt](url) and renders them inline
class _ParsedMessageContent extends StatelessWidget {
  final String text;
  const _ParsedMessageContent({required this.text});

  @override
  Widget build(BuildContext context) {
    // Regex to match standard Markdown images: ![alt](url)
    final imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final matches = imageRegex.allMatches(text);

    if (matches.isEmpty) {
      return _MarkdownText(text: text);
    }

    final List<Widget> children = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // 1. Add text before the image
      if (match.start > lastMatchEnd) {
        final textPart = text.substring(lastMatchEnd, match.start).trim();
        if (textPart.isNotEmpty) {
          children.add(_MarkdownText(text: textPart));
          children.add(const SizedBox(height: 10));
        }
      }

      // 2. Extract image URL and Alt Text
      final altText = match.group(1) ?? '';
      final imageUrl = match.group(2) ?? '';

      // 3. Render the Image
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
                      Icon(Icons.broken_image_rounded, color: AppColors.muted, size: 32),
                      SizedBox(height: 4),
                      Text('Image not available', style: TextStyle(color: AppColors.muted, fontSize: 12)),
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
            ]
          ],
        ),
      );
      children.add(const SizedBox(height: 10));

      lastMatchEnd = match.end;
    }

    // 4. Add any remaining text after the last image
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

/// Lightweight parser to support **bold** text naturally output by LLMs
class _MarkdownText extends StatelessWidget {
  final String text;
  const _MarkdownText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final split = text.split('**');
    
    for (int i = 0; i < split.length; i++) {
      if (split[i].isEmpty) continue;
      // Every odd index in a ** split is the bolded text
      final isBold = i % 2 != 0;
      spans.add(TextSpan(
        text: split[i],
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: AppColors.navy,
          fontSize: 14,
          height: 1.4,
        ),
      ));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: AppColors.deepGold),
      label: Text(label),
      onPressed: isLoading ? null : onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.borderGold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.w800),
    );
  }
}

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
        child: Icon(
          Icons.mic_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
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
                final delay = index * 0.2;
                var progress = (_controller.value - delay).clamp(0.0, 1.0);
                final offset = math.sin(progress * math.pi * 2) * -4;
                return Transform.translate(
                  offset: Offset(0, offset < 0 ? offset : 0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.muted, shape: BoxShape.circle),
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

// ==========================================
// 4. CONTROLLER / STATE MANAGEMENT
// ==========================================

class FaithCopilotController extends ChangeNotifier {
  static final FaithCopilotController instance = FaithCopilotController._internal();
  FaithCopilotController._internal() {
    _messages.add(ChatMessage(
      text: 'Hi! I’m Faith AI, your salon copilot. Tell me the look you want, your budget, or when you want to come in — I’ll help you narrow it down and get ready to book.',
      isUser: false,
    ));
  }

  final _supabase = Supabase.instance.client;
  static const String _aiEndpoint = 'https://dinmax-ai-production.up.railway.app/chat';
  
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
  
  String? lastSuggestedServiceName;
  DateTime? _lastSendAt;

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
    } catch (_) {}

    try {
      final rows = await _supabase
          .from('hair_colors')
          .select()
          .eq('is_active', true)
          .order('code', ascending: true);
      hairColors = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}

    try {
      final rows = await _supabase
          .from('availability_slots')
          .select()
          .eq('is_available', true)
          .gte('slot_date', today)
          .order('slot_date', ascending: true)
          .limit(100);
      availabilitySlots = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      availabilitySlots = [];
    }

    try {
      final rows = await _supabase
          .from('bookings')
          .select(
            'service_id,booking_date,start_time,end_time,status,hair_color_code',
          )
          .gte('booking_date', today)
          .inFilter('status', ['pending', 'confirmed'])
          .order('booking_date', ascending: true)
          .limit(100);
      bookingSignals = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      bookingSignals = [];
    }

    _isLoadingData = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isLoading) return;

    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!).inMilliseconds < 450) {
      return;
    }
    _lastSendAt = now;

    preferences.extractAndRemember(cleanText);
    _messages.add(ChatMessage(text: cleanText, isUser: true));
    _isLoading = true;
    _showBookingButton =
        _showBookingButton || _isBookingIntent(cleanText);
    notifyListeners();

    try {
      final reply = await _fetchAIResponse(cleanText);
      final cleanedReply = _removeRepeatedGreeting(reply);
      _processAIResponse(cleanText, cleanedReply);
    } catch (_) {
      _messages.add(
        ChatMessage(
          text:
              'I could not connect to Faith AI right now. Please try again in a moment.',
          isUser: false,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addSystemMessage(String text) {
    _messages.add(ChatMessage(text: text, isUser: false));
    notifyListeners();
  }

  String _removeRepeatedGreeting(String text) {
    var cleaned = text.trimLeft();

    // Faith AI already has a welcome message in the chat. Do not let every
    // subsequent response start with another greeting or self-introduction.
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

  void _processAIResponse(String userText, String aiText) {
    final detectedServices = _findServicesFromText(aiText);

    if (detectedServices.isEmpty) {
      detectedServices.addAll(_findServicesFromText(userText));
    }

    final imageAttachments = detectedServices
        .map((service) {
          final name = (service['name'] ?? 'Hairstyle').toString().trim();
          final imageUrl = (service['image_url'] ?? '').toString().trim();

          if (imageUrl.isEmpty) return null;

          return ServiceImageAttachment(
            serviceName: name,
            url: imageUrl,
          );
        })
        .whereType<ServiceImageAttachment>()
        .take(3)
        .toList(growable: false);

    _messages.add(
      ChatMessage(
        text: aiText,
        isUser: false,
        serviceImages: imageAttachments,
      ),
    );

    if (detectedServices.isNotEmpty) {
      lastSuggestedServiceName =
          detectedServices.first['name']?.toString();
    }

    final lowerReply = aiText.toLowerCase();
    if (_isBookingIntent(aiText) || lowerReply.contains('open booking')) {
      _showBookingButton = true;
    }
  }

  Future<String> _fetchAIResponse(String customerMessage) async {
    final systemPrompt = AIContextBuilder.buildPrompt(this, customerMessage);

    final response = await http
        .post(
          Uri.parse(_aiEndpoint),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'message': systemPrompt}),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Faith AI server returned ${response.statusCode}.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      final plain = response.body.trim();
      if (plain.isNotEmpty) return plain;
      throw Exception('Faith AI returned an empty response.');
    }

    final answer = _extractAIText(decoded);
    if (answer.isEmpty) {
      throw Exception('Faith AI returned an unreadable response.');
    }
    return answer;
  }

  String _extractAIText(dynamic data) {
    if (data is String) return data.trim();

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

  Map<String, dynamic>? getSuggestedService() {
    if (lastSuggestedServiceName == null) return null;
    try {
      return services.firstWhere((s) => s['name'] == lastSuggestedServiceName);
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

  List<Map<String, dynamic>> _findServicesFromText(String text) {
    final lower = text.toLowerCase();
    final matches = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addService(Map<String, dynamic> service) {
      final key = service['id']?.toString() ??
          service['name']?.toString().toLowerCase() ??
          '';

      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      matches.add(service);
    }

    for (final service in services) {
      final name =
          service['name']?.toString().trim().toLowerCase() ?? '';
      if (name.isNotEmpty && lower.contains(name)) {
        addService(service);
      }
    }

    const aliases = <String, List<String>>{
      'knotless': ['knotless'],
      'fulani': ['fulani'],
      'lemonade': ['lemonade'],
      'senegalese': ['senegalese'],
      'passion': ['passion twist', 'passion twists'],
      'box braid': ['box braid', 'box braids'],
      'twist': ['twist', 'twists'],
      'cornrow': ['cornrow', 'cornrows'],
      'boho': ['boho'],
      'spring': ['spring twist', 'spring'],
      'kids': ['kids', 'kid', 'child'],
      'loc': ['loc', 'locs'],
    };

    for (final entry in aliases.entries) {
      if (!entry.value.any(lower.contains)) continue;

      for (final service in services) {
        final name =
            service['name']?.toString().trim().toLowerCase() ?? '';
        final category =
            service['category']?.toString().trim().toLowerCase() ?? '';

        if (name.contains(entry.key) || category.contains(entry.key)) {
          addService(service);
        }
      }
    }

    return matches.take(3).toList(growable: false);
  }

  Map<String, dynamic>? _findServiceFromText(String text) {
    final lower = text.toLowerCase();

    for (final service in services) {
      final name = service['name']?.toString().trim().toLowerCase() ?? '';
      if (name.isNotEmpty && lower.contains(name)) return service;
    }

    const aliases = <String, List<String>>{
      'knotless': ['knotless'],
      'fulani': ['fulani'],
      'lemonade': ['lemonade'],
      'senegalese': ['senegalese'],
      'twist': ['twist', 'twists'],
      'cornrow': ['cornrow', 'cornrows'],
      'boho': ['boho'],
      'spring': ['spring twist', 'spring'],
      'kids': ['kids', 'kid', 'child'],
      'loc': ['loc', 'locs'],
    };

    for (final entry in aliases.entries) {
      if (!entry.value.any(lower.contains)) continue;

      for (final service in services) {
        final name =
            service['name']?.toString().trim().toLowerCase() ?? '';
        final category =
            service['category']?.toString().trim().toLowerCase() ?? '';

        if (name.contains(entry.key) || category.contains(entry.key)) {
          return service;
        }
      }
    }

    return null;
  }

}

// ==========================================
// 5. DATA CLASSES & UTILS
// ==========================================

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
      r'(?:color|colour)\s*(?:#|number|no\.?|code)?\s*([0-9]{1,3}[a-z]?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (colorMatch != null) color = colorMatch.group(1);

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
    if (mentioned.isNotEmpty) datePreference = mentioned.join(', ');
  }

  String toContextString() {
    final list = [
      if (budget != null) 'Budget: $budget',
      if (length != null) 'Length: $length',
      if (size != null) 'Size: $size',
      if (color != null) 'Color: $color',
      if (occasion != null) 'Occasion: $occasion',
      if (datePreference != null) 'Date/time preference: $datePreference',
    ];
    return list.isEmpty ? 'No preferences set.' : list.join('\n');
  }
}

class AIContextBuilder {
  static String buildPrompt(
    FaithCopilotController controller,
    String latestMessage,
  ) {
    final serviceContext = controller.services.isEmpty
        ? 'No live service records are currently available.'
        : controller.services.map((service) {
            final name = (service['name'] ?? '').toString().trim();
            final category = (service['category'] ?? '').toString().trim();
            final description =
                (service['description'] ?? '').toString().trim();
            final price = _money(service['price']);
            final duration = _duration(service['duration_minutes']);
            final imageUrl =
                (service['image_url'] ?? '').toString().trim();

            return '- $name | category: $category | starting price: $price | '
                'duration: $duration | description: $description | '
                'image_url: ${imageUrl.isEmpty ? 'none' : imageUrl}';
          }).join('\n');

    final colorContext = controller.hairColors.isEmpty
        ? 'No live hair-color records are currently available.'
        : controller.hairColors.map((item) {
            final code = (item['code'] ?? '').toString().trim();
            final name = (item['name'] ?? '').toString().trim();
            return '- $code: $name';
          }).join('\n');

    final availabilityContext = controller.availabilitySlots.isEmpty
        ? 'No dedicated availability-slot records were returned.'
        : controller.availabilitySlots.take(60).map((slot) {
            return '- ${slot['slot_date']} | '
                '${slot['start_time']} to ${slot['end_time']}';
          }).join('\n');

    final occupancyContext = controller.bookingSignals.isEmpty
        ? 'No customer-safe future booking occupancy records were returned.'
        : controller.bookingSignals.take(60).map((booking) {
            return '- service_id: ${booking['service_id']} | '
                'date: ${booking['booking_date']} | '
                'time: ${booking['start_time']} to ${booking['end_time']} | '
                'status: ${booking['status']}';
          }).join('\n');

    final recentMessages = controller.messages.length > 18
        ? controller.messages.sublist(controller.messages.length - 18)
        : controller.messages;

    final chatContext = recentMessages.map((message) {
      return '${message.isUser ? 'Customer' : 'Faith AI'}: ${message.text}';
    }).join('\n');

    return '''
You are Faith AI Copilot, the customer-facing salon assistant for Faith Hair Style.

GOAL
Help the customer choose a hairstyle using the LIVE salon data below, explain
starting prices and durations, remember their preferences, and guide them toward
booking when they are ready.

RULES
- LIVE SERVICES is the source of truth for names, prices, durations, descriptions,
  categories, and service image URLs.
- Always say "starting at" when discussing a service price.
- Never invent a price, duration, service, hair color, discount, deposit,
  cancellation rule, payment method, or appointment availability.
- A business-hour time is not confirmed availability.
- Do not reveal or infer another customer's name, phone, email, notes, or messages.
- SAFE BOOKING OCCUPANCY contains timing/status signals only.
- The app automatically displays the real Supabase image for services you mention.
- Do NOT output Markdown image syntax or raw image URLs.
- Never invent an image URL.
- When the customer is ready to book a known service, tell them to tap the booking button.
- Be concise, friendly, and useful. Ask at most one important follow-up question at a time.
- The chat already contains Faith AI's welcome and introduction.
- Do NOT begin normal follow-up replies with "Good morning", "Good afternoon",
  "Good evening", "Hello", or "Hi".
- Do NOT repeatedly introduce yourself as Faith AI or say "I'm Faith AI".
- After the initial welcome, respond directly to the customer's latest message.

CUSTOMER PREFERENCES
${controller.preferences.toContextString()}

LIVE SERVICES
$serviceContext

LIVE HAIR COLORS
$colorContext

LIVE AVAILABILITY
$availabilityContext

SAFE BOOKING OCCUPANCY
$occupancyContext

RECENT CONVERSATION
$chatContext

LATEST CUSTOMER MESSAGE
$latestMessage
''';
  }

  static String _money(dynamic value) {
    if (value == null) return 'not listed';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    if (parsed == parsed.roundToDouble()) {
      return '\$${parsed.toStringAsFixed(0)}';
    }
    return '\$${parsed.toStringAsFixed(2)}';
  }

  static String _duration(dynamic value) {
    final minutes = int.tryParse(value?.toString() ?? '');
    if (minutes == null || minutes <= 0) return 'not listed';

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (hours == 0) return '$minutes minutes';
    if (remainder == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    return '$hours hr $remainder min';
  }
}

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
