import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../mongodb.dart';
import '../config.dart';
import '../utils/image_upload_utils.dart';
import '../utils/email_notification_utils.dart';
import 'dart:convert';
import '../services/database_service.dart';

class OrganizerEventFormScreen extends StatefulWidget {
  final User organizer;
  final Event? eventToEdit;
  const OrganizerEventFormScreen({super.key, required this.organizer, this.eventToEdit});

  @override
  State<OrganizerEventFormScreen> createState() => _OrganizerEventFormScreenState();
}

class _OrganizerEventFormScreenState extends State<OrganizerEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _slotsController = TextEditingController();
  DateTime? _eventDate;
  String _imageUrl = '';
  bool _isLoading = false;
  Uint8List? _imageBytes;
  bool _isUploadingImage = false;
  bool _generateCertificates = true;
  bool _autoGenerateCertificates = false;
  String _certificateTemplate = 'default';

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _titleController.text = e.title;
      _descController.text = e.description;
      _locationController.text = e.location;
      _slotsController.text = e.totalSlots.toString();
      _eventDate = e.eventDate;
      _imageUrl = e.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickImageFromDevice() async {
    try {
      setState(() => _isUploadingImage = true);
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _isUploadingImage = false;
        });
        
        // Upload to backend
        try {
          final base64Image = base64Encode(bytes);
          final fileName = image.name;
          final fileType = 'image/${fileName.split('.').last}';
          
          final uploadedUrl = await DatabaseService.uploadImage(base64Image, fileName, fileType);
          if (uploadedUrl != null) {
            setState(() {
              _imageUrl = uploadedUrl;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageBytes = null;
      _imageUrl = '';
    });
  }

  Future<String> _saveImageToLocal() async {
    if (_imageBytes == null) return _imageUrl;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/event_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final String fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File imageFile = File('${imagesDir.path}/$fileName');
      await imageFile.writeAsBytes(_imageBytes!);
      
      return imageFile.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return _imageUrl;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _eventDate == null) return;
    setState(() => _isLoading = true);
    try {
      // Save image if selected
      String finalImageUrl = _imageUrl;
      if (_imageBytes != null) {
        finalImageUrl = await _saveImageToLocal();
      }
      
      final event = Event(
        id: widget.eventToEdit?.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        organizerId: widget.organizer.userId,
        organizerName: widget.organizer.name,
        imageUrl: finalImageUrl,
        totalSlots: int.parse(_slotsController.text.trim()),
        availableSlots: widget.eventToEdit?.availableSlots ?? int.parse(_slotsController.text.trim()),
        eventDate: _eventDate!,
        location: _locationController.text.trim(),
        status: 'upcoming',
      );
      
      if (widget.eventToEdit == null) {
        await MongoDataBase.addEvent(event);
        // Send event creation notification to admin
        final success = await EmailNotificationUtils.sendEventCreationNotification(event, widget.organizer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event created! ${EmailNotificationUtils.getNotificationStatus(success, "Event creation")}'),
              backgroundColor: success ? Config.primaryColor : Colors.orange,
            ),
          );
        }
      } else {
        await MongoDataBase.updateEvent(event.id!, {
          'title': event.title,
          'description': event.description,
          'location': event.location,
          'total_slots': event.totalSlots,
          'image_url': event.imageUrl,
          'event_date': event.eventDate.toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPendingApproval = widget.eventToEdit?.pendingApproval ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter event location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _slotsController,
                decoration: const InputDecoration(
                  labelText: 'Total Slots',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter total slots';
                  }
                  final slots = int.tryParse(value);
                  if (slots == null || slots <= 0) {
                    return 'Please enter a valid number of slots';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: isPendingApproval ? null : _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Event Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _eventDate != null
                        ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                        : 'Select Date',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Certificate Settings
              const Text(
                'Certificate Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Generate Certificates'),
                subtitle: const Text('Automatically generate certificates for attendees'),
                value: _generateCertificates,
                onChanged: isPendingApproval ? null : (value) {
                  setState(() {
                    _generateCertificates = value ?? false;
                  });
                },
              ),
              if (_generateCertificates) ...[
                CheckboxListTile(
                  title: const Text('Auto-generate on Attendance'),
                  subtitle: const Text('Generate certificates automatically when attendance is marked'),
                  value: _autoGenerateCertificates,
                  onChanged: isPendingApproval ? null : (value) {
                    setState(() {
                      _autoGenerateCertificates = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _certificateTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Certificate Template',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Default Template')),
                    DropdownMenuItem(value: 'professional', child: Text('Professional Template')),
                    DropdownMenuItem(value: 'creative', child: Text('Creative Template')),
                    DropdownMenuItem(value: 'minimal', child: Text('Minimal Template')),
                  ],
                  onChanged: isPendingApproval ? null : (value) {
                    setState(() {
                      _certificateTemplate = value!;
                    });
                  },
                ),
              ],
              const SizedBox(height: 32),
              
              // Image Upload Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Event Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Image preview
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _imageBytes!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _imageUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.add_photo_alternate, color: Colors.grey),
                                  ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_imageBytes != null || _imageUrl.isNotEmpty) ...[
                              Text(
                                'File size: ${_imageBytes != null ? ImageUploadUtils.getFileSizeString(_imageBytes!.length) : 'Unknown'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isPendingApproval || _isUploadingImage ? null : _pickImageFromDevice,
                                    icon: _isUploadingImage 
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.upload),
                                    label: Text(_isUploadingImage ? 'Uploading...' : 'Upload from Device'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Config.primaryColor,
                                      foregroundColor: Config.secondaryColor,
                                    ),
                                  ),
                                ),
                                if (_imageBytes != null || _imageUrl.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: isPendingApproval ? null : _removeImage,
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Remove Image',
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supported formats: JPG, PNG, WebP, GIF, BMP\nMax size: 10MB',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: isPendingApproval ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primaryColor,
                          foregroundColor: Config.secondaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(widget.eventToEdit == null ? 'Create Event' : 'Update Event'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 