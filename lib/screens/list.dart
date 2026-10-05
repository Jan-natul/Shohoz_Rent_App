import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<DocumentSnapshot> _posts = [];
  bool _loading = true;
  String _city = '';
  RangeValues _priceRange = const RangeValues(0, 100000);
  String _property = 'all';
  bool isFiltered = false;

  @override
  void initState() {
    super.initState();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is String) {
      if (_city != args) {
        _city = args;
        _load();
      }
    } else {
      _load();
    }
  }
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<DocumentSnapshot> data;

      if (isFiltered) {
        data = await ApiService.getPosts(
          city: _city,
          property: _property,
          minPrice: _priceRange.start,
          maxPrice: _priceRange.end,
        );
      } else {
        data = await ApiService.getPosts(city: _city);
      }

      if (mounted) {
        setState(() {
          _posts = data;
          _loading = false;
        });
      }
    } catch (e) {
      print("Load Error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Filter Properties', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54)),
            ]),
            const SizedBox(height: 20),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Search City...', Icons.location_city),
              onChanged: (v) => _city = v,
            ),
            const SizedBox(height: 20),
            const Text('Property Type', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, children: ['all', 'apartment', 'house'].map((p) => ChoiceChip(
              label: Text(p.toUpperCase()),
              selected: _property == p,
              onSelected: (_) => setModal(() => _property = p),
              selectedColor: const Color(0xFFF59E0B),
              labelStyle: TextStyle(color: _property == p ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              showCheckmark: false,
            )).toList()),
            const SizedBox(height: 25),
            Text('Price Range: ${_priceRange.start.toInt()} – ${_priceRange.end.toInt()} Tk', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            RangeSlider(
              values: _priceRange, min: 0, max: 100000,
              activeColor: const Color(0xFFF59E0B), inactiveColor: Colors.white24,
              onChanged: (v) => setModal(() => _priceRange = v),
            ),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isFiltered = true;
                });
                Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )),
            const SizedBox(height: 20),
          ]),
        );
      }),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
    prefixIcon: Icon(icon, color: const Color(0xFFF59E0B), size: 18),
    filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('Available Properties', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [ IconButton(icon: const Icon(Icons.tune, color: Color(0xFFF59E0B)), onPressed: _showFilter) ],
      ),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/homepage.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken))),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
            : SafeArea(
          child: _posts.isEmpty
              ? const Center(child: Text('No properties found.', style: TextStyle(color: Colors.white54, fontSize: 16)))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _posts.length,
            itemBuilder: (ctx, i) => _PostCard(postDoc: _posts[i]),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final DocumentSnapshot postDoc;
  const _PostCard({required this.postDoc});

  @override
  Widget build(BuildContext context) {
    final post = postDoc.data() as Map<String, dynamic>;
    final images = (post['images'] as List?) ?? [];
    final imgUrl = images.isNotEmpty ? images[0] : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/post/${postDoc.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: imgUrl != null
                ? Image.network(imgUrl, width: 120, height: 110, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder())
                : _placeholder(),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.location_on, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text('${post['address']}, ${post['city']}', style: const TextStyle(color: Colors.white60, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${post['price']} Tk', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 15, fontWeight: FontWeight.bold)),
                Row(children: [ _chip(Icons.bed, '${post['bedroom']}'), const SizedBox(width: 8), _chip(Icons.bathtub, '${post['bathroom']}') ]),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(width: 120, height: 110, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.home_work_outlined, color: Colors.white24, size: 30));
  Widget _chip(IconData icon, String label) => Row(children: [Icon(icon, color: Colors.white54, size: 14), const SizedBox(width: 3), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
}