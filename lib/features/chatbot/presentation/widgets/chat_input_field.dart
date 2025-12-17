import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !widget.isLoading,
              style: GoogleFonts.rubik(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: GoogleFonts.rubik(fontSize: 14.sp, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            decoration: BoxDecoration(
              color: widget.isLoading
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: widget.isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white, size: 20.sp),
              onPressed: widget.isLoading ? null : _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}

