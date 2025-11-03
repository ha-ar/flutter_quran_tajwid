import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final double level;

  const AudioVisualizer({
    super.key,
    required this.level,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level != oldWidget.level) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'مستوى الصوت',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'ArabicUI',
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Container(
                width: (widget.level / 100) *
                    (MediaQuery.of(context).size.width - 40),
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _getLevelColor(widget.level),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '${widget.level.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'ArabicUI',
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(double level) {
    if (level < 33) return const Color(0xFF10B981);
    if (level < 66) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
