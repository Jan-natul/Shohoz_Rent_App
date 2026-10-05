import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserDetail extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminUserDetail({super.key, required this.user});

  @override
  State<AdminUserDetail> createState() => _AdminUserDetailState();
}

class _AdminUserDetailState extends State<AdminUserDetail> {
  bool isBlocked = false;
  bool _loadingBlock = false;

  @override
  void initState() {
    super.initState();
    isBlocked = widget.user['isBlocked'] ?? false;
  }

  Future<void> _toggleBlock() async {
    setState(() => _loadingBlock = true);
    try {
      bool newStatus = !isBlocked;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user['id'])
          .update({'isBlocked': newStatus});

      if (mounted) {
        setState(() {
          isBlocked = newStatus;
          _loadingBlock = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingBlock = false);
    }
  }

  Future<void> _togglePostVisibility(String postId, bool currentHiddenStatus) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'isHidden': !currentHiddenStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFF59E0B),
                        backgroundImage: (widget.user['profilePic'] != null && widget.user['profilePic'] != "")
                            ? NetworkImage(widget.user['profilePic'])
                            : null,
                        child: (widget.user['profilePic'] == null || widget.user['profilePic'] == "")
                            ? Text(
                          (widget.user['username'] ?? widget.user['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 30, color: Colors.black, fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                      const SizedBox(height: 15),
                      Text(widget.user['username'] ?? widget.user['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Email: ${widget.user['email'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                      Text("Phone: ${widget.user['phone'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loadingBlock ? null : _toggleBlock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBlocked ? Colors.green : Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _loadingBlock
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isBlocked ? "Unblock User" : "Block User", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text("User's Posts", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: widget.user['uid'] ?? widget.user['id'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No posts found for this user.", style: TextStyle(color: Colors.white38)));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var post = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        String postId = snapshot.data!.docs[index].id;

                        bool postHidden = post['isHidden'] ?? false;
                        String? firstImg;
                        if (post['images'] != null && (post['images'] as List).isNotEmpty) {
                          firstImg = post['images'][0];
                        }

                        return _userPostCard(
                            context,
                            post['title'] ?? 'No Title',
                            "${post['price'] ?? 0} Tk",
                            postId,
                            postHidden,
                            firstImg
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _userPostCard(BuildContext context, String title, String price, String postId, bool isHidden, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: isHidden ? Border.all(color: Colors.redAccent.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        onTap: () => Navigator.pushNamed(context, '/post/$postId'),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 50, height: 50,
            color: Colors.white.withValues(alpha: 0.1),
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.home, color: Color(0xFFF59E0B)))
                : const Icon(Icons.home, color: Color(0xFFF59E0B)),
          ),
        ),
        title: Text(title,
            style: TextStyle(
              color: isHidden ? Colors.white38 : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: isHidden ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis
        ),
        subtitle: Text(price, style: const TextStyle(color: Color(0xFFF59E0B))),
        trailing: IconButton(
          icon: Icon(
              isHidden ? Icons.visibility_off : Icons.visibility,
              color: isHidden ? Colors.redAccent : Colors.green,
              size: 22
          ),
          onPressed: () => _togglePostVisibility(postId, isHidden),
        ),
      ),
    );
  }
}