// Đây là file home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<DocumentSnapshot> latestProducts = []; // danh sách các sản phẩm mới nhất
  List<DocumentSnapshot> hottestProducts =
      []; // danh sách các sản phẩm hot nhất
  bool loading = true; // biến để kiểm tra trạng thái tải dữ liệu
  bool error = false; // biến để kiểm tra trạng thái lỗi

  @override
  void initState() {
    super.initState();
    // lấy dữ liệu từ firestore chỉ một lần
    getProducts();
  }

  String _formatCurrency(num amount) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN');
    return formatCurrency.format(amount);
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

      final snackBarHeight = 0.2;

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
            textColor: Colors.white,
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
      // lấy danh sách các sản phẩm mới nhất, lấy theo document id, cao xuống thấp
      QuerySnapshot snapshot1 = await FirebaseFirestore.instance
          .collection('product')
          .orderBy('id', descending: true)
          .get();
      latestProducts = snapshot1.docs;

      // lấy danh sách các sản phẩm hot nhất, lấy theo field sold, cao xuống thấp
      QuerySnapshot snapshot2 = await FirebaseFirestore.instance
          .collection('product')
          .orderBy('sold', descending: true)
          .get();
      hottestProducts = snapshot2.docs;

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
            "DHT Store",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[800]),
      body: loading
          ? Center(
              child:
                  CircularProgressIndicator()) // hiển thị vòng tròn quay nếu đang tải dữ liệu
          : error
              ? Center(
                  child: Text(
                      "Lỗi khi lấy dữ liệu từ firestore")) // hiển thị thông báo lỗi nếu tải dữ liệu thất bại
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // tạo label cho ô sản phẩm mới nhất
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Sản phẩm mới nhất",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // tạo trang hiển thị dưới dạng trượt ngang danh sách các sản phẩm mới nhất
                      Container(
                        height: 350,
                        child: latestProducts.isEmpty
                            ? Center(
                                child: Text(
                                    "Không có sản phẩm mới nhất")) // hiển thị thông báo nếu không có sản phẩm mới nhất
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: latestProducts.length,
                                itemBuilder: (context, index) {
                                  DocumentSnapshot product =
                                      latestProducts[index];
                                  return Column(
                                    children: [
                                      Image.memory(base64Decode(product[
                                          'image'])), // hiển thị ảnh dưới dạng base64
                                      Text(product[
                                          'name']), // hiển thị tên sản phẩm
                                      Text(
                                        '${_formatCurrency(product['price'])}',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        // tạo hàng ngang chứa các nút
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.shopping_cart_outlined,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              _addToCart(product);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      // tạo label cho ô sản phẩm hot nhất
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Sản phẩm hot nhất",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // tạo trang hiển thị dưới dạng trượt ngang danh sách các sản phẩm hot nhất
                      Container(
                        height: 350,
                        child: hottestProducts.isEmpty
                            ? Center(
                                child: Text(
                                    "Không có sản phẩm hot nhất")) // hiển thị thông báo nếu không có sản phẩm hot nhất
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: hottestProducts.length,
                                itemBuilder: (context, index) {
                                  DocumentSnapshot product =
                                      hottestProducts[index];
                                  return Column(
                                    children: [
                                      Image.memory(base64Decode(product[
                                          'image'])), // hiển thị ảnh dưới dạng base64
                                      Text(product[
                                          'name']), // hiển thị tên sản phẩm
                                      Text(
                                        '${_formatCurrency(product['price'])}',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        // tạo hàng ngang chứa các nút
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.shopping_cart_outlined,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              _addToCart(product);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
