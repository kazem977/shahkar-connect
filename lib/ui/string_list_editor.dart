import 'package:flutter/material.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/settings_tiles.dart';

/// Editable chip list used for split-tunnel apps, domains and trusted networks.
class StringListEditor extends StatefulWidget {
  const StringListEditor({
    super.key,
    required this.icon,
    required this.title,
    required this.values,
    required this.onChanged,
    required this.addLabel,
    required this.hint,
    this.subtitle,
    this.normalize,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String addLabel;
  final String hint;

  /// Optional cleanup applied before an entry is stored.
  final String Function(String raw)? normalize;

  @override
  State<StringListEditor> createState() => _StringListEditorState();
}

class _StringListEditorState extends State<StringListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final value = widget.normalize?.call(raw) ?? raw;
    if (value.isEmpty || widget.values.contains(value)) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((e) => e != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsTileHead(
            icon: widget.icon,
            title: widget.title,
            subtitle: widget.subtitle,
          ),
          if (widget.values.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.values
                  .map(
                    (value) => Container(
                      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171B22),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0xFF23282F)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              color: ShahkarTheme.fog,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _remove(value),
                            icon: const Icon(Icons.close_rounded),
                            iconSize: 13,
                            color: ShahkarTheme.mute,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _add(),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: ShahkarTheme.fog,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        color: ShahkarTheme.mute,
                        fontSize: 11,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      fillColor: const Color(0xFF171B22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: _add,
                  style: FilledButton.styleFrom(
                    backgroundColor: ShahkarTheme.accent.withValues(alpha: 0.2),
                    foregroundColor: ShahkarTheme.accentSoft,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(widget.addLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
