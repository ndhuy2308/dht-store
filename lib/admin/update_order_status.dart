import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderUpdatePage extends StatefulWidget {
  final String orderId;

  OrderUpdatePage({required this.orderId});

  @override
  _OrderUpdatePageState createState() => _OrderUpdatePageState();
}

class _OrderUpdatePageState extends State<OrderUpdatePage> {
  int selectedStatus = 1; // Default status: Chờ xác nhận

  void updateOrderStatus() {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({'status': selectedStatus}).then((value) {
      // Status updated successfully

      final snackBarHeight = 0.2;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cập nhật trạng thái đơn hàng thành công.'),
              const SizedBox(height: 8),
              Text(
                'Thời gian: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    }).catchError((error) {
      // An error occurred while updating status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cập nhật trạng thái đơn hàng',
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Order ID: ${widget.orderId}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            DropdownButton<int>(
              value: selectedStatus,
              onChanged: (newValue) {
                setState(() {
                  selectedStatus = newValue!;
                });
              },
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Chờ xác nhận'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('Đang vận chuyển'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('Đã giao hàng'),
                ),
                DropdownMenuItem(
                  value: 4,
                  child: Text('Đã hủy'),
                ),
              ],
            ),
            SizedBox(height: 20),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: ElevatedButton(
                onPressed: () {
                  updateOrderStatus();
                },
                child: Text(
                  'Hoàn tất',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
