import 'package:flutter/material.dart';
import 'home/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // 1) Controller for a 3 second animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 2) Scale from 0.8× up to 1.2×
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 3) Kick off the animation
    _controller.forward();

    // 4) After 3s, navigate to HomeScreen
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // solid black
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Image.asset('assets/nani.png', width: 200, height: 200),
        ),
      ),
    );
  }
}
