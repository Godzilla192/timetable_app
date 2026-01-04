import 'package:flutter/material.dart';

class HutechAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String slogan;
  final List<Widget>? actions;

  const HutechAppBar({
    super.key,
    required this.slogan,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          Image.asset(
            'assets/hutech.png',
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),

          // đẩy slogan sang phải
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                slogan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
