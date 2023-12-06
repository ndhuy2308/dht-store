// client
import 'package:cuoiky/admin/dashboard.dart';
import 'package:cuoiky/client/cart.dart';
import 'package:cuoiky/client/category.dart';
import 'package:cuoiky/client/order.dart';
import 'profile_page.dart';
import 'package:cuoiky/client/home.dart';

//admin
//import 'package:cuoiky/admin/dashboard.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;
  List<Widget> _pages = [
    Home(),
    Category(),
    Cart(),
    OrdersPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    if (user.email == "huypero114@gmail.com") {
      _pages.add(DashboardPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        unselectedLabelStyle: TextStyle(color: Colors.red),
        showSelectedLabels: true,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.red,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Phân loại',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
          if (user.email == "huypero114@gmail.com")
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Quản lý',
            ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
