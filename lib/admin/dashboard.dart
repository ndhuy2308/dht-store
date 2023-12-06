import 'package:cuoiky/admin/update_category_page.dart';
import 'package:cuoiky/admin/update_order_status.dart';
import 'package:cuoiky/client/home.dart';
import 'package:cuoiky/client/order_page_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'add_product_page.dart';
import 'update_product_page.dart';
import 'package:intl/intl.dart';
import 'add_category_page.dart';

class DashboardPage extends StatelessWidget {
  String _formatCurrency(String amount) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN');
    String normalizedAmount = amount.replaceAll('.0', '');
    return formatCurrency.format(double.parse(normalizedAmount));
  }

  String _formatCurrencyPrice(double price) {
    var format = NumberFormat.simpleCurrency(locale: 'vi_VN');
    return format.format(price);
  }

  String _formatCurrencyTotal(String amount) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN');
    String normalizedAmount = amount.replaceAll('.0', '');
    return formatCurrency.format(double.parse(normalizedAmount));
  }

  String _formatDateTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    return formattedDateTime;
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Quản lý DHT Store",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[800],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Sản phẩm'),
              Tab(text: 'Phân loại'),
              Tab(text: 'Đơn hàng'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('product')
                  .orderBy('id', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length + 1,
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return FractionallySizedBox(
                        widthFactor: 0.7,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Thêm sản phẩm',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                      );
                    }

                    final product = products[index];
                    final data = product.data() as Map<String, dynamic>;
                    final id = product.id;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          data['name'].toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${_formatCurrencyPrice(data['price'])}',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdateProductPage(productId: id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Xóa sản phẩm'),
                                      content: Text(
                                          'Bạn có chắc chắn muốn xóa sản phẩm này?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Hủy'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Xóa'),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('product')
                                                .doc(id)
                                                .delete()
                                                .then((value) {
                                              // Xóa thành công, đóng hộp thoại và làm mới danh sách sản phẩm
                                              Navigator.of(context).pop();
                                            }).catchError((error) {
                                              // Xảy ra lỗi khi xóa sản phẩm
                                              print('Lỗi: $error');
                                              // Hiển thị thông báo lỗi cho người dùng
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('category')
                  .orderBy('id', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == categories.length) {
                      return FractionallySizedBox(
                        widthFactor: 0.7,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddCategoryPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Thêm phân loại',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                      );
                    }

                    final category = categories[index];
                    final data = category.data() as Map<String, dynamic>;
                    final id = category.id;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(data['name'].toString()),
                        subtitle: Text('ID: ${data['id']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                // Chuyển đến trang sửa phân loại và chuyển ID của phân loại đang được nhấn
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdateCategoryPage(categoryId: id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Xóa phân loại'),
                                      content: Text(
                                          'Bạn có chắc chắn muốn xóa phân loại này?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Hủy'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Xóa'),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('category')
                                                .doc(id)
                                                .delete()
                                                .then((value) {
                                              // Xóa thành công, đóng hộp thoại và làm mới danh sách phân loại
                                              Navigator.of(context).pop();
                                            }).catchError((error) {
                                              // Xảy ra lỗi khi xóa phân loại
                                              print('Lỗi: $error');
                                              // Hiển thị thông báo lỗi cho người dùng
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>;
                    final id = data['time'];

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
                            Text('Tài khoản: ${order['email']}'),
                            Text(
                                'Thời gian: ${_formatDateTime(order['time'])}'),
                            Text(
                              '${_formatCurrency(order['totalAmount'])}',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: FractionallySizedBox(
                          widthFactor: 0.4,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OrderUpdatePage(orderId: order.id),
                                ),
                              );
                            },
                            child: Text(
                              'Cập nhật',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                          ),
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
          ],
        ),
      ),
    );
  }
}
