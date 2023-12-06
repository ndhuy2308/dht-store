import 'dart:convert';
import 'package:cuoiky/client/order_page_detail.dart';
import 'package:cuoiky/client/order_page_process.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  CartItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<CartItem> cartItems = [];

  String get totalAmount {
    double total = 0;
    for (var item in cartItems) {
      total += item.price * item.quantity;
    }
    NumberFormat numberFormat = NumberFormat.decimalPattern('vi');
    String formattedAmount = numberFormat.format(total);

    return formattedAmount;
  }

  int get totalQuantity {
    int quantity = 0;
    for (var item in cartItems) {
      quantity += item.quantity;
    }
    return quantity;
  }

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> removeCartItem(int index) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userEmail = user.email!;
        String productId = cartItems[index].productId;

        QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
            .collection('cart')
            .where('email', isEqualTo: userEmail)
            .get();

        String docId = cartSnapshot.docs[index].id;
        await FirebaseFirestore.instance.collection('cart').doc(docId).delete();

        cartItems.removeAt(index);

        setState(() {});
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Đã xảy ra lỗi khi xóa sản phẩm'),
            actions: <Widget>[
              TextButton(
                child: const Text('Đóng'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> fetchCartItems() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userEmail = user.email!;

        QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
            .collection('cart')
            .where('email', isEqualTo: userEmail)
            .get();

        cartItems = [];

        for (var doc in cartSnapshot.docs) {
          var productId = doc['product_id'];
          var productName = doc['product_name'];
          var productSnapshot = await FirebaseFirestore.instance
              .collection('product')
              .doc(productId)
              .get();
          var productData = productSnapshot.data();
          if (productSnapshot.exists && productData != null) {
            var cartItem = CartItem(
              productId: productId,
              name: productName,
              quantity: doc['quantity'],
              price: productData['price'] ?? 0,
            );
            cartItems.add(cartItem);
          }
        }
      }

      setState(() {});
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Đã xảy ra lỗi khi lấy giỏ hàng'),
            actions: <Widget>[
              TextButton(
                child: const Text('Đóng'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> placeOrder() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userEmail = user.email!;

        // Call the placeOrder method from OrderPageProcess
        await OrderPageProcess.placeOrder(context, userEmail, cartItems);

        // Clear the cart
        cartItems.clear();

        setState(() {});

        // Show success dialog or notification
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Thành công'),
              content: const Text('Đơn hàng đã được đặt thành công!'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Đóng'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Đã xảy ra lỗi khi đặt hàng'),
            actions: <Widget>[
              TextButton(
                child: const Text('Đóng'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Giỏ hàng",
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
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text(
                      'Giỏ hàng trống',
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(cartItems[index].name),
                        subtitle:
                            Text('Số lượng: ${cartItems[index].quantity}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            removeCartItem(index);
                          },
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng cộng:'),
                Text(
                  totalAmount + ' đ',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
              width: MediaQuery.of(context).size.width * 0.7,
              margin: EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey; // Màu xám khi nút bị vô hiệu hóa
                      }
                      return Colors.black; // Màu đen mặc định
                    },
                  ),
                ),
                onPressed: cartItems.isEmpty ? null : placeOrder,
                child: const Text(
                  'Đặt hàng',
                  style: TextStyle(color: Colors.white),
                ),
              ))
        ],
      ),
    );
  }
}
