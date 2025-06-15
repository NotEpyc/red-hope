import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_utils.dart';

class EditNewsPage extends StatefulWidget {
  final Map<String, dynamic>? newsItem;
  final int newsIndex;

  const EditNewsPage({
    super.key,
    this.newsItem,
    required this.newsIndex,
  });

  @override
  State<EditNewsPage> createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.newsItem?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.newsItem?['description'] ?? '');
    _imageUrlController = TextEditingController(text: widget.newsItem?['imageUrl'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {      // Create complete news data
      final newsData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': _imageUrlController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Debug log for saving
      final docId = 'news_${widget.newsIndex + 1}';
      debugPrint('Saving news to document: $docId');
      debugPrint('News data: $newsData');
      
      // Save to Firestore with complete document replacement
      await FirebaseFirestore.instance
          .collection('news')
          .doc(docId)
          .set(newsData);  // Remove merge option to force complete update

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving news: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(        title: Text(
          'Edit News',
          style: TextStyle(
            color: Colors.black87,
            fontSize: ResponsiveUtils.getBodySize(context) * 1.2,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveNews,
              icon: const Icon(Icons.save, color: AppTheme.primaryColor),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                      ),                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an image URL';
                        }
                        try {
                          final uri = Uri.parse(value);
                          if (!uri.isAbsolute) {
                            return 'Please enter a complete URL starting with http:// or https://';
                          }
                        } catch (e) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Update UI to show image preview
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_imageUrlController.text.isNotEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Invalid image URL'),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
