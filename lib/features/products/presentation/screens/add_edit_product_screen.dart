import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_pos/features/products/domain/models/product.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:my_pos/features/pos/presentation/widgets/scanner_dialog.dart';
import 'package:my_pos/features/pos/presentation/widgets/barcode_listener.dart';

class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  bool _isActive = true;
  String? _imageUrl;
  File? _imageFile;
  bool _isUploading = false;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final state = context.read<ProductBloc>().state;
      final product =
          state.products.firstWhere((p) => p.id == widget.productId);
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _stockController.text = product.stock.toString();
      _barcodeController.text = product.barcode ?? '';
      _descriptionController.text = product.description ?? '';
      _selectedCategoryId = product.categoryId;
      _isActive = product.isActive;
      _imageUrl = product.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      String? finalImageUrl = _imageUrl;

      if (_imageFile != null) {
        // Upload image logic should be in Repository/Bloc
        // But for simplicity in this turn, I'll assume Bloc handles it or we pass the bytes
        // Actually, let's update ProductCreateRequested/ProductUpdateRequested to optionally take image bytes
      }

      final product = Product(
        id: widget.productId ?? '',
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        barcode: _barcodeController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        imageUrl: finalImageUrl,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEdit) {
        context.read<ProductBloc>().add(ProductUpdateRequested(
              product,
              imageBytes:
                  _imageFile != null ? await _imageFile!.readAsBytes() : null,
              imageName: _imageFile != null
                  ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
                  : null,
            ));
      } else {
        context.read<ProductBloc>().add(ProductCreateRequested(
              product,
              imageBytes:
                  _imageFile != null ? await _imageFile!.readAsBytes() : null,
              imageName: _imageFile != null
                  ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
                  : null,
            ));
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeListener(
      onBarcodeScanned: (code) {
        setState(() => _barcodeController.text = code);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Selection
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            border: Border.all(
                              color:
                                  AppColors.mediumGray.withValues(alpha: 0.3),
                            ),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (_imageUrl != null && _imageUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(_imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _imageFile == null &&
                                  (_imageUrl == null || _imageUrl!.isEmpty)
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        size: 40, color: AppColors.gray),
                                    SizedBox(height: AppSizes.sm),
                                    Text('Add Image',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),

                    // Basic Info
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'Enter product name',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: state.categories.map((c) {
                        return DropdownMenuItem(
                            value: c.id, child: Text(c.name));
                      }).toList(),
                      onChanged: _isUploading
                          ? null
                          : (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: 'Rp ',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: AppSizes.lg),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration:
                                const InputDecoration(labelText: 'Stock'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        suffixIcon: IconButton(
                          onPressed: () => _showScanner(context),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    SwitchListTile(
                      title: const Text('Active Product'),
                      subtitle: const Text('Product will be visible in POS'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(height: AppSizes.huge),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                        child: _isUploading
                            ? const CircularProgressIndicator(
                                color: AppColors.white)
                            : Text(_isEdit ? 'Update Product' : 'Save Product'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ScannerDialog(
        onScanned: (code) {
          setState(() => _barcodeController.text = code);
        },
      ),
    );
  }
}
