import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../pages/produk_detail_page.dart';
import '../widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  //variable utama
  List<ProductModel> products = [];

  //method load produk dari shared preferences
  Future<void> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> productList = prefs.getStringList("products") ?? [];
    if (!mounted) return;
    setState(() {
      products = productList
          .map((item) => ProductModel.fromJson(item))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  //method untuk menyimpan produk ke shared preferences
  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> productList = products.map((item) => item.toJson()).toList();
    await prefs.setStringList("products", productList);
  }

  //method untuk menambahkan produk baru
  Future<void> addProduct(ProductModel product) async {
    setState(() {
      products.add(product);
    });
    await saveProducts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produk berhasil ditambahkan!")),
    );
  }

  //method untuk mengedit produk
  Future<void> editProduct(int index, ProductModel product) async {
    setState(() {
      products[index] = product;
    });
    await saveProducts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produk berhasil diperbarui!")),
    );
  }

  //method untuk menghapus produk
  Future<void> deleteProduct(int index) async {
    setState(() {
      products.removeAt(index);
    });
    await saveProducts();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Produk berhasil dihapus!")));
  }

  //showform untuk tambah/edit produk
  //metode untuk  convert gambar ke base64
  Future<String> convertImageToBase64(XFile image) async {
    Uint8List imageBytes = await image.readAsBytes();

    return base64Encode(imageBytes);
  }
  void showForm({ProductModel? product, int? index}) {
    TextEditingController nameController = TextEditingController(
      text: product?.name ?? "",
    );

    TextEditingController descriptionController = TextEditingController(
      text: product?.description ?? "",
    );

    TextEditingController priceController = TextEditingController(
      text: product?.price.toString() ?? "",
    );

    TextEditingController imageController = TextEditingController(
      text: product?.image ?? "",
    );

    XFile? selectedImage;
    final ImagePicker picker = ImagePicker();

    //method untuk memilih gambar dari galeri
    Future<void> pickImage(StateSetter setDialogState) async {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setDialogState(() {
          selectedImage = image;
          imageController.text = image.path;
        });
      }
    }

    Widget previewImage() {
      // jika menambahkan produk
      if (selectedImage != null) {
        return FutureBuilder<Uint8List>(
          future: selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            return Image.memory(
              snapshot.data!,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            );
          },
        );
      }

      if (product != null && product.image.isNotEmpty) {
        try {
          final bytes = base64Decode(product.image);
          return Image.memory(
            bytes,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      }

      return const SizedBox.shrink();
    }



    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? "Tambah Produk" : "Edit Produk"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nama Produk"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Deskripsi Produk"),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Harga Produk"),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => pickImage(setDialogState),
                icon: const Icon(Icons.photo_library),
                label: const Text("Pilih Gambar"),
              ),
              const SizedBox(height: 12),
              previewImage(),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final productName = nameController.text.trim();
                final productDescription = descriptionController.text.trim();
                final productPrice = int.tryParse(priceController.text) ?? 0;

                if (productName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nama produk tidak boleh kosong"),
                    ),
                  );
                  return;
                }

                final imageBase64 = selectedImage != null
                    ? await convertImageToBase64(selectedImage!)
                    : product?.image ?? "";

                final newProduct = ProductModel(
                  name: productName,
                  description: productDescription,
                  price: productPrice,
                  image: imageBase64,
                );
                Navigator.pop(context);
                if (product == null) {
                  await addProduct(newProduct);
                } else {
                  await editProduct(index!, newProduct);
                }
              },
              child: Text(product == null ? "Simpan" : "Perbaharui"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text("Belum ada produk"))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(product: product),
                            ),
                          ),
                          onEdit: () => showForm(
                            product: products[index],
                            index: index,
                          ),
                          onDelete: () => deleteProduct(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
