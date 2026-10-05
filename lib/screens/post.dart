import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailScreen extends StatefulWidget {
  final String id;
  const PostDetailScreen({super.key, required this.id});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  static const Color goldColor = Color(0xFFF59E0B);
  static const Color bgColor = Color(0xFF0D1520);

  bool _isSaved = false;
  Map<String, dynamic>? _post;
  bool _loading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
    _checkIfSaved();
  }

  Future<void> _fetchPostData() async {
    try {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance.collection('posts').doc(widget.id).get();
      DocumentSnapshot detailDoc = await FirebaseFirestore.instance.collection('postDetails').doc(widget.id).get();

      if (mounted) {
        if (postDoc.exists) {
          setState(() {
            _post = postDoc.data() as Map<String, dynamic>;
            _post!['postDetail'] = detailDoc.data() as Map<String, dynamic>? ?? {};
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showContactPopup() async {
    final String? ownerId = _post!['userId'];

    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Owner information not found")));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _popupContainer(const Center(child: CircularProgressIndicator(color: goldColor)));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _popupContainer(const Center(child: Text("Owner details not available", style: TextStyle(color: Colors.white))));
            }

            var ownerData = snapshot.data!.data() as Map<String, dynamic>;
            String name = ownerData['username'] ?? ownerData['name'] ?? 'N/A';
            String email = ownerData['email'] ?? 'N/A';
            String phone = ownerData['phone'] ?? 'N/A';
            String? profilePic = ownerData['profilePic'];

            return _popupContainer(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: goldColor.withOpacity(0.1),
                    backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                    child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, color: goldColor, size: 40) : null,
                  ),
                  const SizedBox(height: 15),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Property Owner', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 25),

                  _contactTile(Icons.phone, 'Call Owner', phone, () async {
                    final uri = Uri(scheme: 'tel', path: phone);

                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  ),
                  _contactTile(Icons.email, 'Send Email', email, () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: email,
                    );

                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _popupContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF121B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: child,
    );
  }

  Widget _contactTile(IconData icon, String title, String value, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: goldColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: goldColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
    );
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('savedPosts').doc(widget.id).get();
      if (doc.exists && mounted) {
        setState(() => _isSaved = true);
      }
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to save posts")));
      return;
    }

    final saveRef = FirebaseFirestore.instance
        .collection('users').doc(user.uid)
        .collection('savedPosts').doc(widget.id);

    if (_isSaved) {
      await saveRef.delete();
    } else {
      await saveRef.set({'savedAt': DateTime.now()});
    }

    if (mounted) setState(() => _isSaved = !_isSaved);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: bgColor, body: Center(child: CircularProgressIndicator(color: goldColor)));
    if (_post == null) return const Scaffold(backgroundColor: bgColor, body: Center(child: Text("Post not found", style: TextStyle(color: Colors.white))));

    final List images = _post!['images'] ?? [];
    double lat = double.tryParse(_post!['latitude']?.toString() ?? '23.8103') ?? 23.8103;
    double lng = double.tryParse(_post!['longitude']?.toString() ?? '90.4125') ?? 90.4125;

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        color: bgColor,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _toggleSave,
                icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, size: 20),
                label: Text(_isSaved ? 'Saved' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved ? goldColor : Colors.white.withOpacity(0.1),
                  foregroundColor: _isSaved ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _showContactPopup,
                icon: const Icon(Icons.phone, size: 20),
                label: const Text('Contact Owner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350, pinned: true, backgroundColor: bgColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                    itemBuilder: (ctx, i) => Image.network(images[i], fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(color: Colors.white10, child: const Icon(Icons.home, color: Colors.white24))),
                  ),
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: _currentImageIndex == i ? 20 : 8, height: 8, decoration: BoxDecoration(color: _currentImageIndex == i ? goldColor : Colors.white54, borderRadius: BorderRadius.circular(4))))),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post!['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: goldColor, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${_post!['address']}, ${_post!['city']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${_post!['price']} Tk',
                    style: const TextStyle(
                        color: goldColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statChip(Icons.king_bed, '${_post!['bedroom']} Bed'),
                      _statChip(Icons.bathtub, '${_post!['bathroom']} Bath'),
                      _statChip(Icons.square_foot, '${_post!['postDetail']['size'] ?? 0} sqft'),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text('Nearby Places', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _nearbyBox('School', '${_post!['postDetail']['school'] ?? 0}m', Icons.school),
                      _nearbyBox('Bus Stop', '${_post!['postDetail']['bus'] ?? 0}m', Icons.directions_bus),
                      _nearbyBox('Restaurant', '${_post!['postDetail']['restaurant'] ?? 0}m', Icons.restaurant),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text('Location', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () async {
                      final Uri uri = Uri.parse(
                        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                      );

                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        image: DecorationImage(
                          image: NetworkImage('https://static-maps.yandex.ru/1.x/?lang=en_US&ll=$lng,$lat&z=14&l=map&size=600,300'),
                          fit: BoxFit.cover,

                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFF59E0B), size: 36),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: const Text('View on Google Maps', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Description', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(_post!['postDetail']['desc'] ?? '', style: const TextStyle(color: Colors.white70, height: 1.5)),

                  const SizedBox(height: 30),
                  _glassDetailTile('Utilities', _post!['postDetail']['utilities'] ?? 'N/A', Icons.electrical_services),
                  _glassDetailTile('Pet Policy', _post!['postDetail']['pet'] ?? 'N/A', Icons.pets),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))), child: Row(children: [Icon(icon, color: goldColor, size: 16), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))]));
  }
  Widget _glassDetailTile(String label, String value, IconData icon) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, color: goldColor, size: 20), const SizedBox(width: 15), Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 14)), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))]));
  }
  Widget _nearbyBox(String label, String dist, IconData icon) {
    return Container(width: (MediaQuery.of(context).size.width - 60) / 3, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))), child: Column(children: [Icon(icon, color: goldColor, size: 20), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)), const SizedBox(height: 4), Text(dist, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))]));
  }
}