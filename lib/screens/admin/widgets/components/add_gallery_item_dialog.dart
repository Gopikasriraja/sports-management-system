import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../models/gallery_item_model.dart';
import '../../../../../providers/gallery_provider.dart';
import '../../../../../providers/auth_provider.dart';

class AddGalleryItemDialog extends StatefulWidget {
  const AddGalleryItemDialog({super.key});

  @override
  State<AddGalleryItemDialog> createState() => _AddGalleryItemDialogState();
}

class _AddGalleryItemDialogState extends State<AddGalleryItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _eventIdController;

  String _category = 'Sports Day';
  String _mediaType = 'image';

  final List<String> _categories = [
    'Cricket', 'Football', 'Basketball', 'Volleyball', 'Athletics',
    'Chess', 'Yoga', 'Sports Day', 'Tournament', 'Achievement', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _urlController = TextEditingController();
    _eventIdController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _eventIdController.dispose();
    super.dispose();
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<GalleryProvider>(context, listen: false);

      final item = GalleryItemModel(
        galleryId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        eventId: _eventIdController.text,
        mediaType: _mediaType,
        imageUrl: _mediaType == 'image' ? _urlController.text : '',
        videoUrl: _mediaType == 'video' ? _urlController.text : '',
        uploadedBy: auth.currentUser?.name ?? 'Unknown',
        createdAt: DateTime.now(),
      );

      final success = await provider.saveGalleryItem(item);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Error saving item')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Media',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _mediaType,
                        decoration: const InputDecoration(labelText: 'Media Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'image', child: Text('Image')),
                          DropdownMenuItem(value: 'video', child: Text('Video')),
                        ],
                        onChanged: (val) => setState(() => _mediaType = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Media Title', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _eventIdController,
                              decoration: const InputDecoration(labelText: 'Event Tag (Optional)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: '$_mediaType URL',
                          border: const OutlineInputBorder(),
                          hintText: 'Provide direct link to Firebase Storage or Web URL',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Text('Note: In production, this field is populated by Firebase Storage upload via FilePicker. Simulated here for quick creation.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: isDark ? Colors.black : Colors.white),
                  child: const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
