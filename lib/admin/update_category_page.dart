import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateCategoryPage extends StatefulWidget {
  final String categoryId;

  const UpdateCategoryPage({required this.categoryId});

  @override
  _UpdateCategoryPageState createState() => _UpdateCategoryPageState();
}

class _UpdateCategoryPageState extends State<UpdateCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _selectedImage;
  TextEditingController _nameController = TextEditingController();

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final filePath = result.files.first.path;
      final file = File(filePath!);
      final fileBytes = await file.readAsBytes();
      setState(() {
        _selectedImage = fileBytes;
      });
    }
  }

  String imageToBase64(Uint8List image) {
    final base64Image = base64Encode(image);
    return base64Image;
  }

  Future<void> updateCategory() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Please select an image.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      final base64Image = imageToBase64(_selectedImage!);

      final categoryData = {
        'name': _nameController.text,
        'image': base64Image,
      };

      final categoryRef = FirebaseFirestore.instance.collection('category');
      final categoryDoc = categoryRef.doc(widget.categoryId);

      await categoryDoc.update(categoryData);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Category updated successfully.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Pop back to Dashboard
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getCategoryData();
  }

  Future<void> getCategoryData() async {
    final categoryRef = FirebaseFirestore.instance.collection('category');
    final categoryDoc = categoryRef.doc(widget.categoryId);
    final categorySnapshot = await categoryDoc.get();
    final categoryData = categorySnapshot.data() as Map<String, dynamic>;

    final base64Image = categoryData['image'];
    final imageBytes = base64Decode(base64Image);
    setState(() {
      _selectedImage = imageBytes;
      _nameController.text = categoryData['name'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cập nhật phân loại',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[800],
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    pickImage();
                  },
                  child: Container(
                    width: 200.0,
                    height: 200.0,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    child: _selectedImage != null
                        ? InkWell(
                            onTap: () {
                              pickImage();
                            },
                            child: Image.memory(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              pickImage();
                            },
                            child: Icon(Icons.add_a_photo),
                          ),
                  ),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      labelText: 'Tên phân loại', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Vui lòng nhập tên phân loại.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: ElevatedButton(
                      onPressed: () {
                        updateCategory();
                      },
                      child: Text(
                        'Cập nhật phân loại',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
