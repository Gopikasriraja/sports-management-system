import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../models/equipment_model.dart';
import '../../../../../providers/equipment_provider.dart';

class AddEditEquipmentDialog extends StatefulWidget {
  final EquipmentModel? item;

  const AddEditEquipmentDialog({super.key, this.item});

  @override
  State<AddEditEquipmentDialog> createState() => _AddEditEquipmentDialogState();
}

class _AddEditEquipmentDialogState extends State<AddEditEquipmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _supplierCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _remarksCtrl;

  late String _category;
  late String _condition;
  late DateTime _purchaseDate;
  XFile? _pickedImage;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _codeCtrl = TextEditingController(text: item?.equipmentId ?? _generateEquipmentCode());
    _nameCtrl = TextEditingController(text: item?.equipmentName ?? '');
    _brandCtrl = TextEditingController(text: item?.brand ?? '');
    _costCtrl = TextEditingController(text: item?.cost.toString() ?? '0.0');
    _supplierCtrl = TextEditingController(text: item?.supplier ?? '');
    _qtyCtrl = TextEditingController(text: item?.quantity.toString() ?? '1');
    _minStockCtrl = TextEditingController(text: item?.minStockLevel.toString() ?? '2');
    _remarksCtrl = TextEditingController(text: item?.remarks ?? '');

    _category = _isEdit ? item!.category : 'Cricket';
    _condition = _isEdit ? item!.condition : 'Good';
    _purchaseDate = _isEdit ? item!.purchaseDate : DateTime.now();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _costCtrl.dispose();
    _supplierCtrl.dispose();
    _qtyCtrl.dispose();
    _minStockCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  String _generateEquipmentCode() {
    final now = DateTime.now();
    return 'EQ-${DateFormat('yyMMddHHmmss').format(now)}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() {
        _pickedImage = img;
      });
    }
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving equipment record...'), backgroundColor: Colors.blueAccent),
    );

    final provider = Provider.of<EquipmentProvider>(context, listen: false);

    String imageUrl = widget.item?.equipmentImage ?? '';
    if (_pickedImage != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('equipment')
            .child('${_codeCtrl.text}.jpg');
        final bytes = await _pickedImage!.readAsBytes();
        await ref.putData(bytes);
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Storage Upload failed: $e');
      }
    }

    final qty = int.parse(_qtyCtrl.text);
    final minStock = int.parse(_minStockCtrl.text);
    final cost = double.parse(_costCtrl.text);

    int finalAvail = qty;
    int finalIssued = 0;
    int finalDamaged = 0;
    int finalLost = 0;

    if (_isEdit) {
      finalIssued = widget.item!.issuedQuantity;
      finalDamaged = widget.item!.damagedQuantity;
      finalLost = widget.item!.lostQuantity;
      finalAvail = qty - finalIssued - finalDamaged - finalLost;
    } else {
      if (_condition == 'Damaged') {
        finalDamaged = qty;
        finalAvail = 0;
      }
    }

    String finalStatus = 'Available';
    if (finalAvail == 0) {
      finalStatus = 'Out of Stock';
    } else if (finalAvail <= minStock) {
      finalStatus = 'Low Stock';
    }

    final newItem = EquipmentModel(
      equipmentId: _codeCtrl.text.trim(),
      equipmentName: _nameCtrl.text.trim(),
      category: _category,
      quantity: qty,
      availableQuantity: finalAvail,
      issuedQuantity: finalIssued,
      damagedQuantity: finalDamaged,
      lostQuantity: finalLost,
      condition: _condition,
      purchaseDate: _purchaseDate,
      cost: cost,
      brand: _brandCtrl.text.trim(),
      status: finalStatus,
      supplier: _supplierCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim(),
      minStockLevel: minStock,
      equipmentImage: imageUrl,
      isDeleted: false,
    );

    final success = await provider.saveEquipment(newItem);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Equipment specs updated.' : 'Equipment registered in inventory.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Operation failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _isEdit ? Icons.edit_note_rounded : Icons.add_box_rounded,
            color: secondaryColor,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            _isEdit ? 'Update Equipment Specs' : 'Add Sports Equipment',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                          image: _pickedImage != null
                              ? null
                              : (_isEdit && widget.item!.equipmentImage.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(widget.item!.equipmentImage),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: _pickedImage == null && (!_isEdit || widget.item!.equipmentImage.isEmpty)
                            ? Icon(Icons.sports_soccer_rounded, size: 40, color: primaryColor)
                            : (_pickedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FutureBuilder<dynamic>(
                                      future: _pickedImage!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(snapshot.data, fit: BoxFit.cover);
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  )
                                : null),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_rounded, size: 14),
                        label: const Text('Upload Image', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _codeCtrl,
                        enabled: !_isEdit,
                        decoration: const InputDecoration(
                          labelText: 'Equipment Code (Auto) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter code' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Equipment Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter equipment name' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Cricket', 'Football', 'Basketball', 'Volleyball',
                          'Badminton', 'Athletics', 'Chess', 'Table Tennis',
                          'Kabaddi', 'Hockey', 'Yoga', 'Other'
                        ].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _category = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _brandCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Brand *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter brand' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Total Quantity *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter quantity';
                          final numVal = int.tryParse(val);
                          if (numVal == null || numVal < 1) return 'Must be >= 1';
                          if (_isEdit && numVal < widget.item!.issuedQuantity) {
                            return 'Cannot be less than issued qty (${widget.item!.issuedQuantity})';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock Level *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter limit';
                          final numVal = int.tryParse(val);
                          if (numVal == null || numVal < 0) return 'Must be >= 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Purchase Cost (INR) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter cost';
                          final numVal = double.tryParse(val);
                          if (numVal == null || numVal < 0.0) return 'Must be >= 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _purchaseDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today_rounded, size: 16),
                          ),
                          child: Text(DateFormat('dd-MMM-yyyy').format(_purchaseDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supplierCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Supplier details',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _condition,
                        decoration: const InputDecoration(
                          labelText: 'Initial Condition *',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Good', 'Damaged']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _condition = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Comments',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveEquipment,
          child: Text(_isEdit ? 'UpdateSpecs' : 'Add Item'),
        ),
      ],
    );
  }
}
