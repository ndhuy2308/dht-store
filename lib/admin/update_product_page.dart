import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateProductPage extends StatefulWidget {
  final String productId;

  UpdateProductPage({required this.productId});

  @override
  _UpdateProductPageState createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _selectedImage;
  String _categoryValue = '';
  List<Map<String, dynamic>> _categories = [];
  TextEditingController _nameController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _promotionController = TextEditingController();
  TextEditingController _soldController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchProductData();
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

  Future<void> fetchProductData() async {
    final productSnapshot = await FirebaseFirestore.instance
        .collection('product')
        .doc(widget.productId)
        .get();

    if (productSnapshot.exists) {
      final productData = productSnapshot.data() as Map<String, dynamic>;

      setState(() {
        _nameController.text = productData['name'];
        _priceController.text = productData['price'].toString();
        _promotionController.text = productData['promotion'];
        _soldController.text = productData['sold'].toString();
        _descriptionController.text = productData['description'];
        _categoryValue = productData['category'];
        _selectedImage = base64Decode(productData['image']);
      });
    }
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

  Future<void> updateProduct() async {
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

      final categorySnapshot = await FirebaseFirestore.instance
          .collection('category')
          .where('name', isEqualTo: _categoryValue)
          .limit(1)
          .get();

      if (categorySnapshot.docs.isNotEmpty) {
        final categoryId = categorySnapshot.docs.first.id;

        final productData = {
          'name': _nameController.text,
          'price': double.parse(_priceController.text),
          'promotion': _promotionController.text,
          'sold': int.parse(_soldController.text),
          'category': categoryId,
          'description': _descriptionController.text,
          'image': base64Image,
        };

        await FirebaseFirestore.instance
            .collection('product')
            .doc(widget.productId)
            .update(productData);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Product updated successfully.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Cập nhật sản phẩm",
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
                        ? Image.memory(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.add_a_photo),
                  ),
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _categoryValue,
                  onChanged: (newValue) {
                    setState(() {
                      _categoryValue = newValue!;
                    });
                  },
                  items: _categories.map<DropdownMenuItem<String>>(
                    (category) {
                      return DropdownMenuItem<String>(
                        value: category['name'],
                        child: Text(category['name']),
                      );
                    },
                  ).toList(),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a price.';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _promotionController,
                  decoration: InputDecoration(
                    labelText: 'Promotion',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _soldController,
                  decoration: InputDecoration(
                    labelText: 'Sold',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter the number of units sold.';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 16.0),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: ElevatedButton(
                      onPressed: () {
                        updateProduct();
                      },
                      child: Text(
                        'Cập nhật thông tin',
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
