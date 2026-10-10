import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/notifications/domain/notification_repository.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_store.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.store});
  final ChatStore store;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    unawaited(widget.store.load());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    widget.store.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await widget.store.send();
    if (!mounted || !sent) return;
    _input.text = widget.store.draft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: AppDurations.motion(context, AppDurations.state),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(
      title: 'Developify Support',
      leadingInset: 24,
      topInset: 13,
      titleCenterOffset: .5,
    ),
    body: Column(
      children: [
        SizedBox(height: 4.w),
        Container(
          color: AppColors.surface,
          padding: EdgeInsets.fromLTRB(23.w, 15.w, 23.w, 14.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: const BoxDecoration(
                  color: AppColors.emerald600,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'DT',
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                      height: 17 / 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Padding(
                padding: EdgeInsets.only(top: 3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developify Property Team',
                      style: AppTextStyles.text(
                        12,
                        weight: FontWeight.w700,
                        color: AppColors.gray900,
                        height: 14 / 12,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      '● Online · avg reply 12 min',
                      style: AppTextStyles.text(
                        12,
                        weight: FontWeight.w500,
                        color: AppColors.emerald700,
                        height: 14 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Observer(
            builder: (_) {
              if (widget.store.status == LoadStatus.loading) {
                return const LoadingView();
              }
              if (widget.store.status == LoadStatus.error) {
                return ErrorView(
                  message: widget.store.error!,
                  onRetry: widget.store.load,
                );
              }
              return ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(24.w, 26.w, 23.w, 20.w),
                itemCount: widget.store.messages.length,
                itemBuilder: (_, index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: (widget.store.messages[index].outgoing ? 34 : 18).w,
                  ),
                  child: ChatBubble(
                    message: widget.store.messages[index],
                    compact: index < 2,
                  ),
                ),
              );
            },
          ),
        ),
        Observer(builder: (_) => InlineError(widget.store.error)),
        Container(
          padding: EdgeInsets.fromLTRB(
            12.w,
            15.w,
            23.w,
            math.max(12.w, MediaQuery.paddingOf(context).bottom - 3.w),
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48.w,
                  child: TextField(
                    key: const ValueKey('chat-message-input'),
                    controller: _input,
                    onChanged: widget.store.setDraft,
                    onSubmitted: (_) => _send(),
                    style: AppTextStyles.text(14, height: 16 / 14),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: AppTextStyles.text(
                        14,
                        color: AppColors.muted,
                        height: 16 / 14,
                      ),
                      filled: true,
                      fillColor: AppColors.border,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 17.w,
                        vertical: 15.w,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.w),
                        borderSide: const BorderSide(
                          color: AppColors.borderStrong,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.w),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Observer(
                builder: (_) => Semantics(
                  button: true,
                  label: 'Send message',
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap:
                          widget.store.sending ||
                              widget.store.draft.trim().isEmpty
                          ? null
                          : _send,
                      child: SizedBox.square(
                        dimension: 48.w,
                        child: const Center(
                          child: AppIcon(AppAssets.chatSend, size: 15),
                        ),
                      ),
                    ),
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

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.compact = false});
  final ChatMessage message;
  final bool compact;
  @override
  Widget build(BuildContext context) => Align(
    alignment: message.outgoing ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      width: (message.outgoing ? 228 : 237).w,
      constraints: BoxConstraints(minHeight: 74.w),
      padding: EdgeInsets.fromLTRB(
        (message.outgoing ? 10 : 12).w,
        (message.outgoing ? 10 : 8).w,
        (message.outgoing ? 5 : 1).w,
        (message.outgoing ? 10 : 9).w,
      ),
      decoration: BoxDecoration(
        color: message.outgoing ? AppColors.primary : AppColors.surface,
        border: message.outgoing ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: message.outgoing ? 8.w : 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (!message.outgoing && !compact ? 193 : 222).w,
              ),
              child: Text(
                message.text,
                style: AppTextStyles.text(
                  compact ? 11 : 12,
                  weight: FontWeight.w500,
                  color: message.outgoing ? AppColors.white : AppColors.gray900,
                  height: 16 / (compact ? 11 : 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 12.w,
              right: (message.outgoing ? 0 : 16).w,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                message.time,
                style: AppTextStyles.text(
                  9,
                  weight: FontWeight.w500,
                  color: message.outgoing
                      ? AppColors.white
                      : AppColors.iconMuted,
                  height: 10 / 9,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
