import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/screens/admin_details.dart';
import 'package:app/screens/complainList.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _searchQuery = "";
  Map<String, dynamic>? _adminData;
  bool _loadingAdmin = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _adminData = doc.data() as Map<String, dynamic>;
          _loadingAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/homepage.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken)
            )
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 25),

                  _buildAdminProfileCard(),
                  const SizedBox(height: 25),

                  _buildStatsSection(),
                  const SizedBox(height: 10),

                  _buildComplaintBox(context),
                  const SizedBox(height: 25),

                  _buildSearchBar(),
                  const SizedBox(height: 15),

                  const Text("User List Management", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  _buildUserList(),
                ]
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/logo.jpg', width: 40, height: 40,
                      errorBuilder: (c, e, s) => const Icon(Icons.home_work, color: Color(0xFFF59E0B))),
                ),
                const SizedBox(width: 10),
                const Text('Shohoz Admin', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),

          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent)
          ),
        ]
    );
  }

  Widget _buildAdminProfileCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        const CircleAvatar(radius: 25, backgroundColor: Color(0xFFF59E0B), child: Icon(Icons.admin_panel_settings, color: Colors.black)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _loadingAdmin
                ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_adminData?['name'] ?? 'Admin User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(FirebaseAuth.instance.currentUser?.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        IconButton(onPressed: () => Navigator.pushNamed(context, '/update'), icon: const Icon(Icons.edit, color: Color(0xFFF59E0B), size: 20)),
      ]),
    );
  }


  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').snapshots(),
          builder: (context, postSnap) {
            return Row(
              children: [
                Expanded(child: _statTile("Total Users", (userSnap.data?.docs.length ?? 0).toString(), Icons.people)),
                const SizedBox(width: 10),
                Expanded(child: _statTile("Total Posts", (postSnap.data?.docs.length ?? 0).toString(), Icons.post_add)),
              ],
            );
          },
        );
      },
    );
  }


  Widget _statTile(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFFF59E0B), size: 20),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ]),
  );

  Widget _buildComplaintBox(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllComplaintsList())),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.report_problem, color: Colors.redAccent, size: 20),
                SizedBox(width: 15),
                Text('Complaint Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ]),
              Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
            ]
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          hintText: "Search user by name...",
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
      ),
    );
  }

  Widget _buildUserList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));

          var filteredDocs = snapshot.data!.docs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String name = (data['username'] ?? data['name'] ?? "").toString().toLowerCase();
            return name.contains(_searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var userData = filteredDocs[index].data() as Map<String, dynamic>;
              userData['id'] = filteredDocs[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF59E0B),
                      child: Text(userData['name'] != null ? userData['name'][0].toUpperCase() : 'U', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                  ),
                  title: Text(userData['name'] ?? 'Unknown User', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  subtitle: Text(userData['email'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Icon(userData['isAdmin'] == true ? Icons.verified_user : Icons.person_outline, color: userData['isAdmin'] == true ? Colors.blueAccent : Colors.white24, size: 20),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserDetail(user: userData))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class ComplaintDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const ComplaintDetailsPage({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    List images = data['images'] ?? [];
    const Color goldColor = Color(0xFFF59E0B);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Complaint Details', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Complainer Information', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(color: Colors.white10, height: 25),
                      _infoRow(Icons.person, 'Name', data['fullName'] ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _infoRow(Icons.email, 'Email', data['email'] ?? 'N/A'),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text('Complaint Message', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    data['message'] ?? 'No message provided.',
                    style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 30),

                if (images.isNotEmpty) ...[
                  const Text('Attached Photos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: images.length,
                    itemBuilder: (ctx, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: GestureDetector(
                        onTap: () => _showFullImage(context, images[i]),
                        child: Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          FirebaseFirestore.instance.collection('complaints').doc(docId).update({'status': 'resolved'});
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          FirebaseFirestore.instance.collection('complaints').doc(docId).delete();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Dismiss'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Image.network(url, fit: BoxFit.contain),
            Positioned(right: 10, top: 10, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(ctx))),
          ],
        ),
      ),
    );
  }
}