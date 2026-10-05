import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppNavBar extends StatefulWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar> {

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
        child: Row(
          children: [
            Image.asset('assets/logo.jpg',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.home_filled, color: Color(0xFFF59E0B))),
            const SizedBox(width: 10),
            const Text('Shohoz Rent',
                style: TextStyle(color: Color(0xFF232335) , fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [

        _currentUser == null
            ? IconButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          icon: const Icon(Icons.account_circle, color: Color(0xFFF59E0B), size: 28),
        )
            : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
          builder: (context, snapshot) {
            String? profilePicUrl;
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              profilePicUrl = data['profilePic'];
            }

            return IconButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: profilePicUrl != null && profilePicUrl.isNotEmpty
                  ? CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(profilePicUrl),
                backgroundColor: Colors.transparent,
              )
                  : const Icon(Icons.account_circle, color: Color(0xFFF59E0B), size: 28),
            );
          },
        ),

        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF232335), size: 28),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(top: 60, right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _drawerItem(context, Icons.house_rounded, 'Property', '/list'),
              _drawerItem(context, Icons.info_outline, 'About Us', '/about'),
              _drawerItem(context, Icons.contact_support_outlined, 'Contact', '/contact'),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF59E0B), size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}