import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/homepage.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Text('Shohoz Rent',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('The future of house hunting in Bangladesh',
                  style: TextStyle(color: Colors.white60, fontSize: 14), textAlign: TextAlign.center),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                ),
                child: const Column(children: [
                  Text('Our Vision',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(
                    'We started with a simple idea: making house hunting easier, faster, and more transparent. Our goal is to connect homeowners and renters directly through a seamless digital experience.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              Row(children: [
                _featureBox('🏠', 'Easy Search'),
                const SizedBox(width: 12),
                _featureBox('🤝', 'Direct Talk'),
                const SizedBox(width: 12),
                _featureBox('🛡️', 'Verified'),
              ]),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Our Story',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(
                    'Founded in Dhaka, Shohoz Rent understands the local struggle of finding a perfect home. We are building a platform where trust and efficiency come first.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _featureBox(String emoji, String title) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}