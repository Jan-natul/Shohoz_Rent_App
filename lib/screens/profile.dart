import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  List<DocumentSnapshot> _myPosts = [];
  List<DocumentSnapshot> _savedPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        QuerySnapshot postsSnap = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        QuerySnapshot savedSnap = await FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .collection('savedPosts').get();

        List<DocumentSnapshot> tempSaved = [];
        for (var doc in savedSnap.docs) {
          var pDoc = await FirebaseFirestore.instance.collection('posts').doc(doc.id).get();
          if (pDoc.exists) tempSaved.add(pDoc);
        }

        if (mounted) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
            _myPosts = postsSnap.docs;
            _savedPosts = tempSaved;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(String id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("Are you sure you want to delete this property?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      await ApiService.deletePost(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFF59E0B);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () async {
            await ApiService.logout();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }, icon: const Icon(Icons.logout, color: Colors.redAccent))
        ],
      ),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/homepage.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken))),
        child: _loading ? const Center(child: CircularProgressIndicator(color: goldColor)) : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Column(children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: goldColor,
                      backgroundImage: (_userData?['profilePic'] != null && _userData!['profilePic'] != "")
                          ? NetworkImage(_userData!['profilePic'])
                          : null,
                      child: (_userData?['profilePic'] == null || _userData!['profilePic'] == "")
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_userData?['username'] ?? _userData?['name'] ?? 'User Name', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(_userData?['email'] ?? 'No email', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    ])),
                  ]),
                  const SizedBox(height: 20),

                  SizedBox(width: double.infinity, child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/update').then((_) => _loadData());
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update Profile'),
                    style: OutlinedButton.styleFrom(foregroundColor: goldColor, side: const BorderSide(color: goldColor)),
                  )),
                ]),
              ),

              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("My Listings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/add'), icon: const Icon(Icons.add, size: 16), label: const Text("Add New"), style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black))
              ]),
              const SizedBox(height: 15),
              _myPosts.isEmpty
                  ? const Text("You haven't posted anything yet.", style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myPosts.length,
                itemBuilder: (context, index) {
                  return _PostCard(
                    post: _myPosts[index].data() as Map<String, dynamic>,
                    id: _myPosts[index].id,
                    isMine: true,
                    onDelete: () => _deletePost(_myPosts[index].id),
                  );
                },
              ),

              const SizedBox(height: 30),
              const Text("Saved Properties", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _savedPosts.isEmpty
                  ? const Text("No saved properties found.", style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedPosts.length,
                itemBuilder: (context, index) {
                  return _PostCard(
                    post: _savedPosts[index].data() as Map<String, dynamic>,
                    id: _savedPosts[index].id,
                    isMine: false,
                  );
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String id;
  final bool isMine;
  final VoidCallback? onDelete;

  const _PostCard({required this.post, required this.id, required this.isMine, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final images = post['images'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/post/$id'),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: images.isNotEmpty ? Image.network(images[0], width: 70, height: 70, fit: BoxFit.cover) : Container(width: 70, height: 70, color: Colors.white10, child: const Icon(Icons.home, color: Colors.white24))),
        ),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Text('${post['price']} Tk', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
        ])),

        if (isMine)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/add', arguments: id),
                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              ),
            ],
          )
        else
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14)
      ]),
    );
  }
}