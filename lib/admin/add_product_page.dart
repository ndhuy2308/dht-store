import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _selectedImage;
  String _categoryValue = '';
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('category').get();
    final categories = snapshot.docs.map((doc) => doc.data()).toList();
    setState(() {
      _categories = categories;
      _categoryValue = categories.first['name'];
    });
  }

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

  Future<void> addProduct() async {
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

      final productRef = FirebaseFirestore.instance.collection('product').doc();
      final CollectionReference collectionRef =
          FirebaseFirestore.instance.collection('product');

      int documentCount = 0;

      collectionRef.get().then((QuerySnapshot snapshot) {
        documentCount = snapshot.size;
      }).catchError((error) {
        print('Error: $error');
      });

      final productId = productRef.id;

      final categorySnapshot = await FirebaseFirestore.instance
          .collection('category')
          .where('name', isEqualTo: _categoryValue)
          .limit(1)
          .get();

      if (categorySnapshot.docs.isNotEmpty) {
        final categoryId = categorySnapshot.docs.first.id;

        final productData = {
          'id': documentCount,
          'name': _nameController.text,
          'price': double.parse(_priceController.text),
          'promotion': _promotionController.text,
          'sold': int.parse(_soldController.text),
          'category': categoryId,
          'description': _descriptionController.text,
          'image': base64Image,
        };

        await productRef.set(productData);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Product added successfully.'),
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
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Selected category not found.'),
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
      }
    }
  }

  TextEditingController _nameController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _promotionController = TextEditingController();
  TextEditingController _soldController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Thêm sản phẩm",
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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                      labelText: 'Price', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a price';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _promotionController,
                  decoration: InputDecoration(
                      labelText: 'Promotion', border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _soldController,
                  decoration: InputDecoration(
                      labelText: 'Sold', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter the number of sold items';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _categoryValue,
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['name'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryValue = value!;
                    });
                  },
                  decoration: InputDecoration(
                      labelText: 'Category',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Product Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Center(
                  child: _selectedImage != null
                      ? Image.memory(_selectedImage!)
                      : Text('Vui lòng chọn ảnh'),
                ),
                SizedBox(height: 8),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: ElevatedButton(
                      onPressed: pickImage,
                      child: Text(
                        'Chọn ảnh',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: ElevatedButton(
                      onPressed: addProduct,
                      child: Text(
                        'Thêm sản phẩm',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
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
