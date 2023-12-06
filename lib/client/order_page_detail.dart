import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class OrderPageDetail extends StatelessWidget {
  final String orderId;

  const OrderPageDetail({Key? key, required this.orderId}) : super(key: key);
  String _formatCurrencyTotal(String amount) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN');
    String normalizedAmount = amount.replaceAll('.0', '');
    return formatCurrency.format(double.parse(normalizedAmount));
  }

  String _formatCurrency(num amount) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN');
    return formatCurrency.format(amount);
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Chờ xác nhận';
      case 2:
        return 'Đang vận chuyển';
      case 3:
        return 'Đã giao hàng';
      case 4:
        return 'Đã hủy';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    if (status == 1) {
      return Colors.brown;
    } else if (status == 2) {
      return Colors.blue;
    } else if (status == 3) {
      return Colors.green;
    } else if (status == 4) {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chi tiết đơn hàng",
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('An error occurred');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue, // Thay đổi màu cho vòng tròn chờ
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Text('Order not found');
          }

          var orderData = snapshot.data!.data() as Map<String, dynamic>;

          // Retrieve user details based on the email
          var userEmail = orderData['email'] as String;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(userEmail)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return const Text(
                    'An error occurred while retrieving user data');
              }

              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue, // Thay đổi màu cho vòng tròn chờ
                  ),
                );
              }

              var userData = userSnapshot.data!.data() as Map<String, dynamic>;

              var products = orderData['products'] as Map<String, dynamic>?;

              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn hàng: ${snapshot.data!.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${_getStatusText(orderData['status'])}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(orderData['status']),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Tổng tiền: ${_formatCurrencyTotal(orderData['totalAmount'])}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Địa chỉ giao hàng: ${userData['address']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Tên: ${userData['first name']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Họ: ${userData['last name']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Số điện thoại: ${userData['phone number']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Sản phẩm đã đặt:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: products?.length ?? 0,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          var productId = products!.keys.elementAt(index);
                          var product =
                              products[productId] as Map<String, dynamic>;
                          var quantity = product['quantity'];
                          var price = product['price'];

                          return ListTile(
                            title: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('product')
                                  .doc(productId)
                                  .get(),
                              builder: (context, productSnapshot) {
                                if (productSnapshot.hasError) {
                                  return const Text(
                                      'An error occurred while retrieving product data');
                                }

                                if (productSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                    ),
                                  );
                                }

                                var productData = productSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                var productName = productData['name'];
                                var productImage = productData['image'];
                                var decodedImage = base64Decode(productImage);

                                return Row(
                                  children: [
                                    Image.memory(
                                      decodedImage,
                                      width: 50,
                                      height: 50,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productName,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            'Số lượng: $quantity',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            trailing: Text(
                              _formatCurrency(price),
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
