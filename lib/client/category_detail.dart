import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class CategoryDetail extends StatefulWidget {
  final String categoryId; // biến để lưu id của phân loại
  const CategoryDetail(this.categoryId, {Key? key}) : super(key: key);

  @override
  State<CategoryDetail> createState() => _CategoryDetailState();
}

class _CategoryDetailState extends State<CategoryDetail> {
  List<DocumentSnapshot> products = []; // danh sách các sản phẩm theo phân loại
  bool loading = true; // biến để kiểm tra trạng thái tải dữ liệu
  bool error = false; // biến để kiểm tra trạng thái lỗi

  @override
  void initState() {
    super.initState();
    // lấy dữ liệu từ firestore chỉ một lần
    getProducts();
  }

  Future<void> _addToCart(DocumentSnapshot product) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      String userEmail = user.email!;

      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('email', isEqualTo: userEmail)
          .where('product_id', isEqualTo: product.id)
          .limit(1)
          .get();

      if (cartSnapshot.size > 0) {
        DocumentSnapshot cartItem = cartSnapshot.docs[0];
        int quantity = cartItem['quantity'] + 1;

        await FirebaseFirestore.instance
            .collection('cart')
            .doc(cartItem.id)
            .update({'quantity': quantity});
      } else {
        await FirebaseFirestore.instance.collection('cart').add({
          'email': userEmail,
          'product_id': product.id,
          'product_name': product['name'],
          'quantity': 1,
          'time': DateTime.now(),
        });
      }

      final snackBarHeight =
          0.2; // Tỷ lệ chiều cao của SnackBar so với chiều cao màn hình

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sản phẩm đã được thêm vào giỏ hàng'),
              const SizedBox(height: 8),
              Text(
                  'Thời gian: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
            ],
          ),
          action: SnackBarAction(
            label: 'Đóng',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xảy ra lỗi khi thêm sản phẩm vào giỏ hàng'),
          action: SnackBarAction(
            label: 'Đóng',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  // hàm để lấy dữ liệu từ firestore
  Future<void> getProducts() async {
    try {
      // lấy danh sách các sản phẩm theo phân loại
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('product')
          .where('category',
              isEqualTo: widget.categoryId) // lọc các sản phẩm theo phân loại
          .get();
      products = snapshot.docs;

      // cập nhật trạng thái tải dữ liệu thành công
      setState(() {
        loading = false;
        error = false;
      });
    } catch (e) {
      // cập nhật trạng thái tải dữ liệu thất bại
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sản phẩm theo phân loại",
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
      body: loading
          ? Center(
              child:
                  CircularProgressIndicator()) // hiển thị vòng tròn quay nếu đang tải dữ liệu
          : error
              ? Center(
                  child: Text(
                      "Lỗi khi lấy dữ liệu từ firestore")) // hiển thị thông báo lỗi nếu tải dữ liệu thất bại
              : products.isEmpty
                  ? Center(
                      child: Text(
                          "Phân loại này chưa có sản phẩm")) // hiển thị thông báo khi không có sản phẩm
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot product = products[index];
                        return Container(
                          height: 350,
                          child: Column(
                            children: [
                              Image.memory(base64Decode(product[
                                  'image'])), // hiển thị ảnh dưới dạng base64
                              Text(product['name']), // hiển thị tên sản phẩm
                              Text(product['price']
                                  .toString()), // hiển thị giá sản phẩm
                              Row(
                                // tạo hàng ngang chứa các nút
                                children: [
                                  IconButton(
                                    // tạo nút giỏ hàng
                                    icon: Icon(Icons.shopping_cart),
                                    onPressed: () {
                                      _addToCart(product);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
