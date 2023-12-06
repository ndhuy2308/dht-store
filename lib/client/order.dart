import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'order_page_detail.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  User? _user;
  Stream<QuerySnapshot>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: _user!.email)
          .orderBy('time', descending: true)
          .snapshots();
    }
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

  String _formatDateTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    return formattedDateTime;
  }

  String _formatCurrency(String amount) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN');
    String normalizedAmount = amount.replaceAll('.0', '');
    return formatCurrency.format(double.parse(normalizedAmount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đơn hàng của tôi",
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
      body: _user == null
          ? const Text('No user signed in')
          : StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Đã xảy ra lỗi');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: const Text('Không có đơn hàng'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var order = snapshot.data!.docs[index];
                    return Card(
                      elevation: 5,
                      child: ListTile(
                        title: Text('Đơn hàng ${order.id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getStatusText(order['status'])}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(order['status']),
                              ),
                            ),
                            Text(
                                'Thời gian: ${_formatDateTime(order['time'])}'),
                            Text(
                              '${_formatCurrency(order['totalAmount'])}',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderPageDetail(
                                orderId: order.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
