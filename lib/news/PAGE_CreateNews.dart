import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'MODEL_News.dart';
import 'SERVICE_uploadNews.dart';

class CreateNews extends StatefulWidget {
  @override
  CreateNewsState createState() => CreateNewsState();
}

class CreateNewsState extends State<CreateNews> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final List<XFile?> selectedImages = [];
  final ImagePicker picker = ImagePicker();
  int? pickedIndex = 0;
  String downloadUrl = '';

  Future<void> pickImage() async {
    if (selectedImages.length < 3) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedImages.add(image);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only add up to 3 images.'),
        ),
      );
    }
  }
 
  //this works
  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  //doesn't work
  Future<List<String>> uploadImagesToSupabase(BuildContext context) async {

  List<String> uploadedImageUrls = [];

  for (int i = 0; i < selectedImages.length; i++) {
    final String fileName;
    try {
      final XFile image = selectedImages[i]!;
      final File file = File(image.path);
      final compressedFile = await _compressAndConvertImage(file);
      if (compressedFile == null) {
        throw Exception('Failed to compress the image.');
      }
       fileName = 'news${pickedIndex}/${pickedIndex}-$i.webp';
      await Supabase.instance.client.storage.from('images').upload(
            fileName,
            compressedFile,
          );
      final downloadUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(fileName);
      uploadedImageUrls.add(downloadUrl);
      print('Uploaded new file: $fileName');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }
  return uploadedImageUrls;
}

  Future<void> removeRecord() async {
    for(int i = 0; i <= 2; i++){
      try {
    // List all files in the folder
        final files = await Supabase.instance.client.storage
            .from('images')
            .list(path: 'news$pickedIndex');
        print('first file ${files[0].name}');
        final filePaths = files.map((file) => 'news${pickedIndex}/${file.name}').toList();
        if (filePaths.isNotEmpty) {
          await Supabase.instance.client.storage
              .from('images')
              .remove(filePaths);
          print('Deleted all files in the folder: news${pickedIndex}/');
        } else {
          print('No files found in the folder: news${pickedIndex}/');
        }
      } catch (e) {
        print('Error deleting folder: $e');
      }
    }
  }

  Future<File?> _compressAndConvertImage(File file) async {
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
      final compressedFile = File('${tempDir.path}/compressed_image_${DateTime.now().millisecondsSinceEpoch}.webp');
      await compressedFile.writeAsBytes(compressedImage);
      return compressedFile;
    } catch (e) {
      print('Error during image processing: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create News'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pictures:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Image'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedImages.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(selectedImages.length, (index) {
                  return Stack(
                    children: [
                      Image.file(
                        File(selectedImages[index]!.path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => removeImage(index),
                          child: Container(
                            color: Colors.black54,
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: pickedIndex,
              decoration: const InputDecoration(labelText: 'News Number'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0')),
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
              ],
              onChanged: (value) {
                setState(() {
                  pickedIndex = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleting news\$pickedIndex')),
                    );
                    await removeRecord();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are ready to go!!')),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Clear folder',
                      maxLines: 2,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () async {
                    if (titleController.text.isEmpty || contentController.text.isEmpty || selectedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please complete all fields and add at least one image.')),
                      );
                      return;
                    }
                    List<String> imageUrls = await uploadImagesToSupabase(context);
                    if (imageUrls.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to upload images.')),
                      );
                      return;
                    }
                    final newsService = NewsService();
                    // to firebase
                    await newsService.uploadNews(
                      NewsModel(
                        title: titleController.text,
                        content: contentController.text,
                        imageLinks: imageUrls,
                        newsNumber: pickedIndex!,
                      )
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('News Created Successfully!')),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Create News',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
            ],),
          ],
        ),
      ),
    );
  }
}
