import 'dart:async';
import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double speed; // pixels per second
  final Duration pauseDuration;

  const MarqueeText({
    Key? key,
    required this.text,
    required this.style,
    this.speed = 65.0, // increased speed for a snappier feel (up from previous slow duration)
    this.pauseDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (_isScrolling) return;
    _isScrolling = true;
    _scroll();
  }

  void _scroll() async {
    if (!mounted || !_scrollController.hasClients) {
      _isScrolling = false;
      return;
    }
    
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent <= 0) {
      // Check again shortly in case layout changes size
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _scroll();
      return;
    }

    final double speed = widget.speed;
    final scrollDuration = Duration(milliseconds: (maxScrollExtent / speed * 1000).toInt());

    // 1. Pause at start
    await Future.delayed(widget.pauseDuration);
    if (!mounted || !_scrollController.hasClients) {
      _isScrolling = false;
      return;
    }

    // 2. Scroll to end
    await _scrollController.animateTo(
      maxScrollExtent,
      duration: scrollDuration,
      curve: Curves.linear,
    );
    if (!mounted || !_scrollController.hasClients) {
      _isScrolling = false;
      return;
    }

    // 3. Pause at end
    await Future.delayed(widget.pauseDuration);
    if (!mounted || !_scrollController.hasClients) {
      _isScrolling = false;
      return;
    }

    // 4. Scroll back to start
    await _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
    if (!mounted || !_scrollController.hasClients) {
      _isScrolling = false;
      return;
    }

    // 5. Repeat
    _scroll();
  }

  @override
  void dispose() {
    _isScrolling = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
