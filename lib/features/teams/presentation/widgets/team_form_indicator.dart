import 'package:flutter/material.dart';

class TeamFormIndicator extends StatelessWidget {
  final List<String> form;
  final double size;

  const TeamFormIndicator({
    super.key,
    required this.form,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (form.isEmpty) {
      return const Text(
        'NO DATA',
        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: form.take(5).map((result) => _buildResultDot(result)).toList(),
    );
  }

  Widget _buildResultDot(String result) {
    Color color;
    switch (result.toUpperCase()) {
      case 'W':
        color = Colors.green;
        break;
      case 'D':
        color = Colors.grey;
        break;
      case 'L':
        color = Colors.red;
        break;
      default:
        color = Colors.blueGrey;
    }

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          result,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
