import 'package:flutter/material.dart';
import 'package:pertemuan10_2306033/models/product_model.dart';

class ProductDetailPage extends StatelessWidget {
  // variable untuk menampilkan data produk yang dipilih
  final ProductModel product;

  // constructor
  const ProductDetailPage({super.key, required this.product});

  // widget builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Produk"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(product.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Rp ${product.price}"),
            const SizedBox(height: 10),
            Text(product.description),
          ],
        ),
      ),
    );
  }
}