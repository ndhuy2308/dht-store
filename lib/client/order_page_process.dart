import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'cart.dart';

class OrderPageProcess {
  static Future<void> placeOrder(
      BuildContext context, String userEmail, List<CartItem> cartItems) async {
    try {
      // Construct the products JSON object
      Map<String, dynamic> products = {};
      for (var item in cartItems) {
        products[item.productId] = {
          'quantity': item.quantity,
          'price': item.price,
        };
      }

      // Create a new order document
      await FirebaseFirestore.instance.collection('orders').add({
        'email': userEmail,
        'products': products,
        'status': 1, // Newly created status
        'totalAmount': calculateTotalAmount(cartItems),
        'shipping': 'cod',
        'time': FieldValue.serverTimestamp(),
      });

      List<Future<void>> updateFutures = [];
      for (var item in cartItems) {
        updateFutures.add(FirebaseFirestore.instance
            .collection('product')
            .doc(item.productId)
            .update({
          'sold': FieldValue.increment(item.quantity),
        }));
      }
      await Future.wait(updateFutures);

      await clearCart(userEmail);
    } catch (e) {
      print('Error placing order: $e');
    }
  }

  static Future<void> clearCart(String userEmail) async {
    try {
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('email', isEqualTo: userEmail)
          .get();

      List<Future<void>> deleteFutures = [];

      for (var doc in cartSnapshot.docs) {
        deleteFutures.add(doc.reference.delete());
      }

      await Future.wait(deleteFutures);

      print('Cart cleared successfully!');
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  static String calculateTotalAmount(List<CartItem> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      total += item.price * item.quantity;
    }
    String result = total.toString();
    return result;
  }
}
