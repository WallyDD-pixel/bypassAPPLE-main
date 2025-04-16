import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' show sin, cos;

class BackgroundWidget extends StatefulWidget {
  const BackgroundWidget({super.key});

  @override
  State<BackgroundWidget> createState() => _BackgroundWidgetState();
}

class _BackgroundWidgetState extends State<BackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade900, Colors.black],
            ),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Premier cercle (vert)
                      Positioned(
                        top: 50 + (40 * _animation.value),
                        left: 30 + (30 * _animation.value),
                        child: Transform.rotate(
                          angle: _animation.value * 4 * 3.14,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.shade700.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                      // Deuxième cercle (vert foncé)
                      Positioned(
                        bottom: 200 - (35 * _animation.value),
                        right: 30 - (30 * _animation.value),
                        child: Transform.rotate(
                          angle: -_animation.value * 4 * 3.14,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color.fromARGB(
                                255,
                                26,
                                143,
                                3,
                              ).withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                      // Nouveau cercle (bleu)
                      Positioned(
                        top: 150 + (50 * sin(_animation.value * 2 * 3.14)),
                        right: 100 + (50 * cos(_animation.value * 2 * 3.14)),
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * _animation.value),
                          child: Transform.rotate(
                            angle: _animation.value * 6 * 3.14,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromARGB(
                                  255,
                                  22,
                                  136,
                                  7,
                                ).withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        // Effet de flou animé
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20 + (15 * _animation.value),
                sigmaY: 20 + (15 * _animation.value),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.2 + (0.1 * _animation.value)),
              ),
            );
          },
        ),
      ],
    );
  }
}
