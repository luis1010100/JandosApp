import 'package:flutter/material.dart';
import '../widgets/tool_loader.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: ToolLoader(size: 80)),
    );
  }
}
