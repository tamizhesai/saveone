import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_storage_service.dart';
import '../models/document_model.dart';

class DocsPage extends StatefulWidget {
  const DocsPage({super.key});

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final docs = await _dbService.getUserDocuments(user.id!);
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;
        final fileExtension = fileName.split('.').last;
        final fileType = 'application/$fileExtension';

        final user = await _authService.getCurrentUser();
        if (user != null) {
          final uploadResult = await _storageService.uploadFile(
            file: file,
            userId: user.id!,
            fileName: fileName,
          );

          if (uploadResult != null) {
            final success = await _dbService.uploadDocument(
              userId: user.id!,
              fileName: fileName,
              firebaseUrl: uploadResult['firebase_url']!,
              firebasePath: uploadResult['firebase_path']!,
              fileSize: fileSize,
              fileType: fileType,
            );

            setState(() => _isUploading = false);

            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document uploaded successfully'),
                  backgroundColor: AppTheme.primary,
                ),
              );
              _loadDocuments();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to save document metadata'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            setState(() => _isUploading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload file to Firebase'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toUpperCase();
  }

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.fileName}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _storageService.deleteFile(doc.firebasePath);
      final success = await _dbService.deleteDocument(doc.id!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted'),
            backgroundColor: AppTheme.primary,
          ),
        );
        _loadDocuments();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadDocument(DocumentModel doc) async {
    try {
      final Uri url = Uri.parse(doc.firebaseUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        elevation: 0,
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _pickAndUploadFile,
              tooltip: 'Upload Document',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: AppTheme.textDark.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No documents yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textDark.withOpacity(0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to upload',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textDark.withOpacity(0.4),
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: () => _downloadDocument(doc),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _getFileExtension(doc.fileName),
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            doc.fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _formatFileSize(doc.fileSize),
                                style: TextStyle(
                                  color: AppTheme.textDark.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Uploaded: ${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
                                style: TextStyle(
                                  color: AppTheme.textDark.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteDocument(doc),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
