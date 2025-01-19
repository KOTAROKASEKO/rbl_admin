import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:rbl_admin/couponService/CouponCloudService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';


class CouponCreateView extends StatefulWidget {
  const CouponCreateView({super.key});

  @override
  _CouponCreateViewState createState() => _CouponCreateViewState();
}

class _CouponCreateViewState extends State<CouponCreateView> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountValueController = TextEditingController();
  String? _discountType;
  DateTime? _validUntil;
  File? _imageFile;
  String downloadUrl = '';

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  Future uploadImage(BuildContext context) async {
  if (_imageFile == null) return;

  // Compress and convert the image before uploading
  final compressedFile = await _compressAndConvertImage(_imageFile!);

  if (compressedFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('画像の圧縮に失敗しました。')),
    );
    return;
  }

  // Generate a unique file path
  final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  final path = 'uploads/$fileName';

  try {
    // Upload the image to Supabase storage
    await Supabase.instance.client.storage
        .from('images')
        .upload(path, compressedFile);

    downloadUrl = Supabase.instance.client.storage
        .from('images')
        .getPublicUrl(path);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('画像をアップロードしました！')),
    );
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('画像のアップロードに失敗しました: $e')),
    );
  }
}

  static Future<File?> _compressAndConvertImage(File file) async {
    try {
      final imageBytes = await file.readAsBytes();
      final compressedImage = await FlutterImageCompress.compressWithList(

        imageBytes,
        format: CompressFormat.webp,
        minWidth: 800,
        minHeight: 600,
        quality: 75,
        
      );

      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/compressed_image.webp');
      await compressedFile.writeAsBytes(compressedImage);
      return compressedFile;
    } catch (e) {
      print('Error during image processing: $e');
      return null;
    }
  }

  Future<void> _uploadCoupon(String couponId) async {
    if (_discountType == null ||
        _validUntil == null ||
        _discountValueController.text.isEmpty||
        _descriptionController.text.isEmpty||
        int.tryParse(_discountValueController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('error happened during setting up in the coupon collection。')),
      );
      return;
    }

    try {
      await uploadImage(context);

      await FirebaseFirestore.instance.collection('coupons').doc(couponId).set({
        'isForEveryone':true,
        'couponId': couponId,
        'description': _descriptionController.text,
        'discountType': _discountType,
        'discountValue': int.parse(_discountValueController.text),
        'validUntil': _validUntil,
        'imageUrl': downloadUrl,
        'whoUsed':[],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('coupon was uploaded successfully')),
      );
      _resetFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error happened during setting up in the coupon collection: $e')),
      );
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _validUntil = pickedDate;
      });
    }
  }

  void _resetFields() {
    setState(() {
      _descriptionController.clear();
      _discountValueController.clear();
      _discountType = null;
      _validUntil = null;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[200],
                child: _imageFile == null
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : Image.file(_imageFile!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'title'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _discountType,
              decoration: const InputDecoration(labelText: 'discount type'),
              items: const [
                DropdownMenuItem(value: 'ratio discount', child: Text('ratio discount(%)')),
                DropdownMenuItem(value: 'subtraction', child: Text('subtraction(RM)')),
              ],
              onChanged: (value) {
                setState(() {
                  _discountType = value;
                  _discountValueController.clear(); // Clear the value field when type changes
                });
              },
            ),
            if (_discountType == 'ratio discount')
              TextField(
                controller: _discountValueController,
                decoration: const InputDecoration(
                  labelText: 'how much (%)',
                  hintText: 'example: 10',
                ),
                keyboardType: TextInputType.number,
              ),
            if (_discountType == 'subtraction')
              TextField(
                controller: _discountValueController,
                decoration: const InputDecoration(
                  labelText: 'discount value (RM)',
                  hintText: 'e.g: 20',
                ),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(_validUntil == null
                    ? 'select expiry  date'
                    : 'expires on: ${_validUntil!.toLocal().year}/${_validUntil!.toLocal().month}/${_validUntil!.toLocal().day}'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () async{
                  var uuid = Uuid();
                  String id = uuid.v4();
                  print('generated Coupon ID is ${id}');
                  try{
                    await _uploadCoupon(id);
                    await couponCloudService.addCouponToAllUsers(id);
                  }catch(e){
                    print('error happened $e');
                    }
                  },
                child:Container(
                  width: 190,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child:Center(
                    child:Text('upload',style: TextStyle(color: Colors.white),)
                  )
              ))
            ),
          ],
        ),
        )      
        ),
    );
  }
}
