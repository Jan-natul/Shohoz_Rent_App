import 'package:flutter/material.dart';
import 'package:app/widget/navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cityController = TextEditingController();

  void _search() {
    final city = _cityController.text.trim();
    Navigator.pushNamed(context, '/list', arguments: city);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavBar(),
      endDrawer: const AppDrawer(),
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.25),

                const Text('Hello, User!', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 5),
                const Text('Find Your Dream Home',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),

                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search city (e.g. Dhaka)',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      IconButton(
                        onPressed: _search,
                        icon: const Icon(Icons.search, color: Color(0xFFF59E0B)),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text('Quick Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(child: _statCard('1000+', 'Properties', Icons.home)),
                    const SizedBox(width: 15),
                    Expanded(child: _statCard('50+', 'Cities', Icons.location_city)),
                  ],
                ),
                const SizedBox(height: 15),
                _statCard('500+', 'Happy Renters', Icons.sentiment_very_satisfied, fullWidth: true),

                const SizedBox(height: 40),

                const Center(
                  child: Text('© 2024 Shohoz Rent - All Rights Reserved',
                      style: TextStyle(color: Colors.white24, fontSize: 10)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}