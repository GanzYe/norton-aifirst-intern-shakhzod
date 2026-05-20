import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Reports the laid-out size of [child] after each frame.
class MeasureSize extends StatefulWidget {
  const MeasureSize({
    super.key,
    required this.onChange,
    required this.child,
  });

  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  final _key = GlobalKey();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void didUpdateWidget(covariant MeasureSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(Duration _) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final size = box.size;
    if (_lastSize == size) {
      return;
    }
    _lastSize = size;
    widget.onChange(size);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
