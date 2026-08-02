import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';

class AddHouseScreen extends StatefulWidget {
  const AddHouseScreen({super.key});
  @override
  State<AddHouseScreen> createState() => _AddHouseScreenState();
}

class _AddHouseScreenState extends State<AddHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _error = '';
  String? _editId;

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _size = TextEditingController();
  final _bus = TextEditingController();
  final _school = TextEditingController();
  final _restaurant = TextEditingController();

  String _property = 'apartment';
  String _petPolicy = 'Allowed';
  String _utilities = 'Owner responsible';
  int _bedroom = 1;
  int _bathroom = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String && _editId == null) {
      _editId = args;
      _loadDataForEdit(args);
    }
  }

  Future<void> _loadDataForEdit(String id) async {
    setState(() => _loading = true);
    try {
      var postDoc = await FirebaseFirestore.instance.collection('posts').doc(id).get();
      var detailDoc = await FirebaseFirestore.instance.collection('postDetails').doc(id).get();

      if (postDoc.exists) {
        var p = postDoc.data()!;
        var d = detailDoc.data()!;
        setState(() {
          _title.text = p['title'] ?? '';
          _address.text = p['address'] ?? '';
          _city.text = p['city'] ?? '';
          _price.text = p['price'].toString();
          _lat.text = p['latitude'] ?? '';
          _lng.text = p['longitude'] ?? '';
          _bedroom = p['bedroom'] ?? 1;
          _bathroom = p['bathroom'] ?? 1;
          _property = p['property'] ?? 'apartment';

          _desc.text = d['desc'] ?? '';
          _size.text = d['size'].toString();
          _school.text = d['school'].toString();
          _bus.text = d['bus'].toString();
          _restaurant.text = d['restaurant'].toString();
          _petPolicy = d['pet'] ?? 'Allowed';
          _utilities = d['utilities'] ?? 'Owner responsible';

          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_editId == null && _selectedImages.isEmpty) {
      setState(() => _error = "Please select images");
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {

      final Map<String, dynamic> postDataMap = {
        'title': _title.text,
        'price': int.tryParse(_price.text) ?? 0,
        'address': _address.text,
        'city': _city.text.trim().isNotEmpty
            ? _city.text.trim()[0].toUpperCase() + _city.text.trim().substring(1).toLowerCase()
            : '',

      'bedroom': _bedroom,
        'bathroom': _bathroom,
        'property': _property,
        'latitude': _lat.text,
        'longitude': _lng.text,
      };

      final Map<String, dynamic> detailDataMap = {
        'desc': _desc.text,
        'utilities': _utilities,
        'pet': _petPolicy,
        'size': int.tryParse(_size.text) ?? 0,
        'school': int.tryParse(_school.text) ?? 0,
        'bus': int.tryParse(_bus.text) ?? 0,
        'restaurant': int.tryParse(_restaurant.text) ?? 0,
      };

      if (_editId != null) {

        await FirebaseFirestore.instance.collection('posts').doc(_editId).update(postDataMap);
        await FirebaseFirestore.instance.collection('postDetails').doc(_editId).update(detailDataMap);

        if (mounted) Navigator.pop(context);
      } else {

        final data = {
          'postData': postDataMap,
          'postDetail': detailDataMap,
        };
        final res = await ApiService.createPost(data, _selectedImages);
        if (mounted) Navigator.pushReplacementNamed(context, '/post/${res['id']}');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(_editId != null ? 'Edit Property' : 'Add Property', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/homepage.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken))),
        child: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))) : SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_error.isNotEmpty) _errorWidget(),
                _glassCard([
                  _sectionLabel('Basic Information'),
                  _field('Property Title', _title, required: true),
                  const SizedBox(height: 15),
                  _field('Full Address', _address, required: true),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _field('City', _city, required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Price (Tk)', _price, required: true, number: true)),
                  ]),
                ]),
                const SizedBox(height: 20),
                _glassCard([
                  _sectionLabel('Facilities'),
                  _field('Description', _desc, required: true, lines: 3),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _dropdown('Type', ['apartment', 'house', 'office'], _property, (v) => setState(() => _property = v!))),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Size(sqft)', _size, number: true)),
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _dropdown('Bed', ['1','2','3','4','5','6'], _bedroom.toString(), (v) => setState(() => _bedroom = int.parse(v!)))),
                    const SizedBox(width: 12),
                    Expanded(child: _dropdown('Bath', ['1','2','3','4','5'], _bathroom.toString(), (v) => setState(() => _bathroom = int.parse(v!)))),
                  ]),

                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                        child: _dropdown('Pet Policy', ['Allowed', 'Not Allowed'], _petPolicy, (v) => setState(() => _petPolicy = v!))
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _dropdown('Utilities', ['Owner responsible', 'Renter responsible', 'Shared'], _utilities, (v) => setState(() => _utilities = v!))
                    ),
                  ]),

                ]),
                const SizedBox(height: 20),
                _glassCard([
                  _sectionLabel('Nearby (Meters)'),
                  Row(children: [
                    Expanded(child: _field('Latitude', _lat, required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Longitude', _lng, required: true)),
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _field('School', _school, number: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field('Bus', _bus, number: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field('Restaurant', _restaurant, number: true)),
                  ]),
                ]),
                const SizedBox(height: 20),
                if (_editId == null)
                  _glassCard([
                    _sectionLabel('Property Images'),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _pickImages, icon: const Icon(Icons.add_a_photo, color: Color(0xFFF59E0B)), label: const Text('Select Images', style: TextStyle(color: Colors.white)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFF59E0B))))),
                    if (_selectedImages.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 15), child: SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _selectedImages.length, itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.only(right: 10), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: kIsWeb ? Image.network(_selectedImages[i].path, width: 80, height: 80, fit: BoxFit.cover) : Image.file(File(_selectedImages[i].path), width: 80, height: 80, fit: BoxFit.cover)))))),
                  ]),
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(_editId != null ? 'Update Property' : 'Add Property Now', style: const TextStyle(fontWeight: FontWeight.bold)))),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorWidget() => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5))), child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
  Widget _glassCard(List<Widget> children) => Container(padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
  Widget _sectionLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(label, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 15, fontWeight: FontWeight.bold)));
  Widget _field(String label, TextEditingController ctrl, {bool required = false, bool number = false, int lines = 1}) => TextFormField(controller: ctrl, maxLines: lines, keyboardType: number ? TextInputType.number : TextInputType.text, style: const TextStyle(color: Colors.white, fontSize: 14), validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null, decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60, fontSize: 13), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))), contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14)));
  Widget _dropdown(String label, List<String> items, String currentValue, ValueChanged<String?> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: currentValue,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF0D1B2A),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase()))).toList(),
        ),
      ]);
}